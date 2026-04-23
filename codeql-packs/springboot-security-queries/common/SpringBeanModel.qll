/**
 * common/SpringBeanModel.qll
 *
 * 最小 Spring DI 语义层：
 * 1. bean 类型识别：
 *    - @Controller / @Service / @Component / @Repository
 *    - @Configuration + @Bean
 * 2. 注入点识别：
 *    - @Autowired / @Inject / @Resource
 *    - 单构造器注入（single-constructor injection）
 *    - setter injection
 * 3. 候选实现识别：接口/抽象类型 -> 具体 bean 实现
 * 4. scope 粗粒度：singleton / prototype
 * 5. @Primary / @Qualifier 最小支持
 *
 * 说明：
 * - 这里只做“查询可用”的语义抽象，不做 100% Spring 容器模拟
 * - 暂不处理 XML 配置、复杂条件装配
 */

import java

private predicate hasQualifiedAnnotation(Annotatable a, string pkg, string name) {
  exists(Annotation ann |
    ann = a.getAnAnnotation() and
    ann.getType().hasQualifiedName(pkg, name)
  )
}

private predicate hasBeanAnnotation(Annotatable a) {
  hasQualifiedAnnotation(a, "org.springframework.context.annotation", "Bean")
}

private predicate isConfigurationType(RefType t) {
  hasQualifiedAnnotation(t, "org.springframework.context.annotation", "Configuration")
}

private predicate isBeanFactoryMethod(Method m) {
  hasBeanAnnotation(m) and
  isConfigurationType(m.getDeclaringType())
}

private predicate getBeanFactoryProducedType(Method m, RefType t) {
  t = m.getReturnType()
}

private predicate getBeanFactoryName(Method m, string name) {
  exists(Annotation ann |
    ann = m.getAnAnnotation() and
    ann.getType().hasQualifiedName("org.springframework.context.annotation", "Bean") and
    name = ann.getStringValue("name") and
    name != ""
  )
  or
  exists(Annotation ann |
    ann = m.getAnAnnotation() and
    ann.getType().hasQualifiedName("org.springframework.context.annotation", "Bean") and
    name = ann.getStringValue("value") and
    name != ""
  )
  or
  name = m.getName()
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

private predicate isBeanProducedType(RefType t) {
  exists(Method m |
    isBeanFactoryMethod(m) and
    getBeanFactoryProducedType(m, t)
  )
}

predicate isSpringBeanType(RefType t) {
  exists(Annotation ann |
    ann = t.getAnAnnotation() and
    isSpringBeanStereotype(ann)
  )
  or
  isBeanProducedType(t)
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

/**
 * 单构造器注入：
 * - 所在 bean 类型只有一个构造器
 * - 且该构造器至少有一个参数
 */
private predicate isSingleInjectConstructor(Constructor c) {
  exists(RefType beanType |
    beanType = c.getDeclaringType() and
    isSpringBeanType(beanType) and
    c.getNumberOfParameters() > 0 and
    not exists(Constructor other |
      other.getDeclaringType() = beanType and
      other != c
    )
  )
}

predicate isInjectedConstructor(Constructor c) {
  exists(Annotation ann |
    ann = c.getAnAnnotation() and
    isConstructorInjectAnnotation(ann)
  )
  or
  isSingleInjectConstructor(c)
}

/**
 * setter injection：
 * - setXxx(...)
 * - 恰好一个参数
 * - 方法或参数上带 @Autowired / @Inject / @Resource
 */
predicate isInjectedSetter(Method m) {
  m.getName().matches("set%") and
  m.getNumberOfParameters() = 1 and
  not m.isStatic() and
  (
    exists(Annotation ann |
      ann = m.getAnAnnotation() and
      isInjectAnnotation(ann)
    )
    or
    exists(Parameter p, Annotation ann |
      p = m.getParameter(0) and
      ann = p.getAnAnnotation() and
      isInjectAnnotation(ann)
    )
  )
}

/**
 * 参数注入点：
 * - 构造器参数：
 *   - 参数自己带 @Inject / @Resource / @Autowired
 *   - 或其所在构造器带 @Autowired / @Inject
 *   - 或其所在构造器是单构造器注入
 * - setter 参数：
 *   - 所在 setter 方法被识别为注入 setter
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
  or
  exists(Method m |
    m = p.getCallable() and
    isInjectedSetter(m) and
    p = m.getParameter(0)
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
  or
  exists(Method m |
    isBeanFactoryMethod(m) and
    getBeanFactoryProducedType(m, t) and
    hasQualifiedAnnotation(m, "org.springframework.context.annotation", "Primary")
  )
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
 * - setter 方法本身上的同类注解（给 setter 参数补充）
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
  or
  exists(Parameter p, Method m, Annotation ann |
    injectionPoint = p and
    m = p.getCallable() and
    isInjectedSetter(m) and
    ann = m.getAnAnnotation() and
    isQualifierStyleAnnotation(ann) and
    qualifier = ann.getStringValue("value") and
    qualifier != ""
  )
  or
  exists(Parameter p, Method m, Annotation ann |
    injectionPoint = p and
    m = p.getCallable() and
    isInjectedSetter(m) and
    ann = m.getAnAnnotation() and
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
 * - @Bean(name/value="x")
 * - 默认使用 @Bean 方法名
 */
predicate getBeanQualifier(RefType t, string qualifier) {
  exists(Annotation ann |
    ann = t.getAnAnnotation() and
    isQualifierStyleAnnotation(ann) and
    qualifier = ann.getStringValue("value") and
    qualifier != ""
  )
  or
  exists(Method m, Annotation ann |
    isBeanFactoryMethod(m) and
    getBeanFactoryProducedType(m, t) and
    ann = m.getAnAnnotation() and
    isQualifierStyleAnnotation(ann) and
    qualifier = ann.getStringValue("value") and
    qualifier != ""
  )
  or
  exists(Method m |
    isBeanFactoryMethod(m) and
    getBeanFactoryProducedType(m, t) and
    getBeanFactoryName(m, qualifier)
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
 * - impl 可以是：
 *   1) 具体 class（不是 interface/abstract）
 *   2) 或 @Bean 工厂方法直接产出的类型
 * - impl 必须是 Spring bean
 * - impl == depType，或者 impl 继承/实现 depType
 */
predicate isBeanCandidateType(RefType depType, RefType impl) {
  (
    exists(Class c |
      c = impl and
      not c.isAbstract()
    )
    or
    isBeanProducedType(impl)
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

/** -----------------------------
 *  DI resolution / alias helpers
 *  -----------------------------
 * 目的：
 * 1) 字段注入：把“字段读取”连到 preferred bean 类型
 * 2) 构造器 / setter 注入：把“参数注入”连到“对象字段”
 *
 * 注意：
 * - 这里只提供“查询可消费”的解析谓词
 * - 不直接修改 CodeQL 全局数据流框架
 */

/**
 * 直接注解字段注入得到的 preferred bean 类型
 */
predicate getInjectedFieldPreferredBeanType(Field f, RefType impl) {
  isInjectedField(f) and
  isPreferredBeanCandidateForInjection(f, impl)
}

/**
 * 构造器 / setter 注入参数最终写入了哪个字段
 *
 * 识别两类常见赋值：
 *   this.f = p;
 *   f = p;          // own field access
 */
predicate injectedParameterAssignedToField(Parameter p, Field f) {
  exists(Assignment a, FieldAccess lhs, VarAccess rhs |
    isInjectedParameter(p) and
    a.getEnclosingCallable() = p.getCallable() and
    lhs = a.getDest() and
    rhs = a.getSource() and
    lhs.getField() = f and
    rhs.getVariable() = p and
    (
      lhs.isOwnFieldAccess()
      or
      lhs.getQualifier() instanceof ThisAccess
    )
  )
}

/**
 * 通过构造器 / setter 参数注入，最终落到字段上的 preferred bean 类型
 */
predicate getParameterBackedFieldPreferredBeanType(Field f, RefType impl) {
  exists(Parameter p |
    injectedParameterAssignedToField(p, f) and
    isPreferredBeanCandidateForInjection(p, impl)
  )
}

/**
 * 统一后的“字段背后可能是哪种 bean 类型”
 *
 * 包含：
 * - 直接字段注入
 * - 构造器 / setter 参数注入后写入字段
 */
predicate getResolvedInjectedFieldBeanType(Field f, RefType impl) {
  getInjectedFieldPreferredBeanType(f, impl)
  or
  getParameterBackedFieldPreferredBeanType(f, impl)
}

/**
 * 某次字段读取，是否可视为读取到了某个注入 bean 类型
 *
 * 这里只近似处理 own field / this.field，
 * 不尝试跨对象精确还原 obj.field。
 */
predicate injectedFieldReadMayResolveToBeanType(FieldAccess fa, RefType impl) {
  exists(Field f |
    fa.getField() = f and
    getResolvedInjectedFieldBeanType(f, impl) and
    (
      fa.isOwnFieldAccess()
      or
      fa.getQualifier() instanceof ThisAccess
    )
  )
}

/**
 * 某次方法调用是否是“通过注入依赖字段发起”的
 *
 * 例如：
 *   this.userService.find(...)
 *   userService.find(...)
 */
predicate injectedFieldReceiverCallMayResolveToBeanType(MethodCall call, RefType impl) {
  exists(FieldAccess recv |
    recv = call.getQualifier() and
    injectedFieldReadMayResolveToBeanType(recv, impl)
  )
}