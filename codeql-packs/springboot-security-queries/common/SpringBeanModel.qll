/**
 * common/SpringBeanModel.qll
 *
 * 最小 Spring DI 语义层：
 * 1. bean 类型识别：@Controller / @Service / @Component / @Repository
 * 2. 注入点识别：@Autowired / @Inject / @Resource
 * 3. 候选实现识别：接口/抽象类型 -> 具体 bean 实现
 * 4. scope 粗粒度：singleton / prototype
 * 5. @Primary / @Qualifier 最小支持
 *
 * 说明：
 * - 这里只做“查询可用”的语义抽象，不做 100% Spring 容器模拟
 * - 暂不处理 @Bean factory method、XML 配置、setter injection、复杂条件装配
 */

import java

private predicate hasQualifiedAnnotation(Annotatable a, string pkg, string name) {
  exists(Annotation ann |
    ann = a.getAnAnnotation() and
    ann.getType().hasQualifiedName(pkg, name)
  )
}

/** -----------------------------
 *  Bean stereotypes
 *  ----------------------------- */
private predicate isSpringBeanStereotype(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.stereotype", "Controller") or
  ann.getType().hasQualifiedName("org.springframework.stereotype", "Service") or
  ann.getType().hasQualifiedName("org.springframework.stereotype", "Component") or
  ann.getType().hasQualifiedName("org.springframework.stereotype", "Repository")
}

predicate isSpringBeanType(RefType t) {
  exists(Annotation ann |
    ann = t.getAnAnnotation() and
    isSpringBeanStereotype(ann)
  )
}

class SpringBeanType extends RefType {
  SpringBeanType() { isSpringBeanType(this) }
}

/** -----------------------------
 *  Injection points
 *  ----------------------------- */
private predicate isInjectAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.beans.factory.annotation", "Autowired") or
  ann.getType().hasQualifiedName("javax.inject", "Inject") or
  ann.getType().hasQualifiedName("jakarta.inject", "Inject") or
  ann.getType().hasQualifiedName("javax.annotation", "Resource") or
  ann.getType().hasQualifiedName("jakarta.annotation", "Resource")
}

private predicate isConstructorInjectAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.beans.factory.annotation", "Autowired") or
  ann.getType().hasQualifiedName("javax.inject", "Inject") or
  ann.getType().hasQualifiedName("jakarta.inject", "Inject")
}

predicate isInjectedField(Field f) {
  exists(Annotation ann |
    ann = f.getAnAnnotation() and
    isInjectAnnotation(ann)
  )
}

predicate isInjectedConstructor(Constructor c) {
  exists(Annotation ann |
    ann = c.getAnAnnotation() and
    isConstructorInjectAnnotation(ann)
  )
}

/**
 * 构造器参数注入点：
 * - 参数自己带 @Inject / @Resource / @Autowired
 * - 或其所在构造器带 @Autowired / @Inject
 */
predicate isInjectedParameter(Parameter p) {
  exists(Constructor c |
    c = p.getCallable() and
    (
      isInjectedConstructor(c)
      or
      exists(Annotation ann |
        ann = p.getAnAnnotation() and
        isInjectAnnotation(ann)
      )
    )
  )
}

/** -----------------------------
 *  Dependency type of injection point
 *  ----------------------------- */
predicate getInjectionPointType(Annotatable injectionPoint, RefType depType) {
  exists(Field f |
    injectionPoint = f and
    depType = f.getType()
  )
  or
  exists(Parameter p |
    injectionPoint = p and
    depType = p.getType()
  )
}

/** -----------------------------
 *  Scope
 *  ----------------------------- */
private predicate hasScopeValue(RefType t, string scopeValue) {
  exists(Annotation ann |
    ann = t.getAnAnnotation() and
    ann.getType().hasQualifiedName("org.springframework.context.annotation", "Scope") and
    scopeValue = ann.getStringValue("value")
  )
}

predicate isPrototypeBeanType(RefType t) {
  isSpringBeanType(t) and
  hasScopeValue(t, "prototype")
}

predicate isSingletonBeanType(RefType t) {
  isSpringBeanType(t) and
  not isPrototypeBeanType(t)
}

/** -----------------------------
 *  @Primary / @Qualifier
 *  ----------------------------- */
predicate isPrimaryBeanType(RefType t) {
  hasQualifiedAnnotation(t, "org.springframework.context.annotation", "Primary")
}

private predicate isQualifierStyleAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.beans.factory.annotation", "Qualifier") or
  ann.getType().hasQualifiedName("javax.inject", "Named") or
  ann.getType().hasQualifiedName("jakarta.inject", "Named")
}

/**
 * 注入点上的 qualifier：
 * - @Qualifier("x")
 * - @Named("x")
 * - @Resource(name="x")
 */
predicate getInjectionQualifier(Annotatable injectionPoint, string qualifier) {
  exists(Annotation ann |
    ann = injectionPoint.getAnAnnotation() and
    isQualifierStyleAnnotation(ann) and
    qualifier = ann.getStringValue("value") and
    qualifier != ""
  )
  or
  exists(Annotation ann |
    ann = injectionPoint.getAnAnnotation() and
    (
      ann.getType().hasQualifiedName("javax.annotation", "Resource")
      or
      ann.getType().hasQualifiedName("jakarta.annotation", "Resource")
    ) and
    qualifier = ann.getStringValue("name") and
    qualifier != ""
  )
}

/**
 * bean 类型上的 qualifier：
 * - @Qualifier("x")
 * - @Named("x")
 *
 * 这里只做最小支持，不做默认 bean name 推导。
 */
predicate getBeanQualifier(RefType t, string qualifier) {
  exists(Annotation ann |
    ann = t.getAnAnnotation() and
    isQualifierStyleAnnotation(ann) and
    qualifier = ann.getStringValue("value") and
    qualifier != ""
  )
}

predicate isQualifierCompatible(Annotatable injectionPoint, RefType impl) {
  not exists(string q | getInjectionQualifier(injectionPoint, q))
  or
  exists(string q |
    getInjectionQualifier(injectionPoint, q) and
    getBeanQualifier(impl, q)
  )
}

/** -----------------------------
 *  Candidate implementations
 *  ----------------------------- 
 * depType 的候选实现：
 * - impl 必须是具体 class（不是 interface/abstract）
 * - impl 必须是 Spring bean
 * - impl == depType，或者 impl 继承/实现 depType
 */
predicate isBeanCandidateType(RefType depType, RefType impl) {
  exists(Class c |
    c = impl and
    not c.isAbstract()
  ) and
  isSpringBeanType(impl) and
  (
    impl = depType
    or
    impl.getAStrictAncestor() = depType
  )
}

predicate isBeanCandidateForInjection(Annotatable injectionPoint, RefType impl) {
  exists(RefType depType |
    getInjectionPointType(injectionPoint, depType) and
    isBeanCandidateType(depType, impl) and
    isQualifierCompatible(injectionPoint, impl)
  )
}

/**
 * “优先候选”：
 * - 注入点显式写了 qualifier，则匹配 qualifier 的候选算 preferred
 * - 否则 @Primary 算 preferred
 * - 否则如果只有一个候选，也算 preferred
 */
predicate isPreferredBeanCandidateForInjection(Annotatable injectionPoint, RefType impl) {
  isBeanCandidateForInjection(injectionPoint, impl) and
  (
    exists(string q | getInjectionQualifier(injectionPoint, q))
    or
    isPrimaryBeanType(impl)
    or
    not exists(RefType other |
      other != impl and
      isBeanCandidateForInjection(injectionPoint, other)
    )
  )
}