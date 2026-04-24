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

/**
 * -----------------------------
 * Component scan approximation
 * -----------------------------
 *
 * 目标：
 * - 支持 @SpringBootApplication 默认扫描包
 * - 支持 @SpringBootApplication(scanBasePackages / scanBasePackageClasses)
 * - 支持 @ComponentScan(value / basePackages / basePackageClasses)
 * - 支持 @ComponentScans 包装形式
 * - 支持自定义 stereotype，即元注解带 @Component
 * - 仅支持低成本 excludeFilters:
 *   1) FilterType.ANNOTATION
 *   2) FilterType.ASSIGNABLE_TYPE
 *
 * 不处理：
 * - @Profile / @Conditional 的运行期条件
 * - starter 自动配置
 * - XML component-scan
 * - includeFilters 的复杂扩展
 * - REGEX / ASPECTJ / CUSTOM filter
 */

private predicate isComponentScanAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.context.annotation", "ComponentScan")
}

private predicate isComponentScansAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.context.annotation", "ComponentScans")
}

private predicate isSpringBootApplicationAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.boot.autoconfigure", "SpringBootApplication")
}

/**
 * 直接或通过 @ComponentScans 取得 @ComponentScan。
 */
private predicate getDeclaredComponentScanAnnotation(RefType configType, Annotation scan) {
  scan = configType.getAnAnnotation() and
  isComponentScanAnnotation(scan)
  or
  exists(Annotation scans |
    scans = configType.getAnAnnotation() and
    isComponentScansAnnotation(scans) and
    scan = scans.getAnArrayValue("value")
  )
}

/**
 * 读取注解上的 String 或 String[] 属性。
 *
 * 例如：
 * - @ComponentScan("com.foo")
 * - @ComponentScan(basePackages = {"com.foo", "com.bar"})
 * - @SpringBootApplication(scanBasePackages = "com.foo")
 */
private predicate getAnnotationStringOrStringArrayValue(Annotation ann, string attr, string value) {
  value = ann.getStringValue(attr) and
  value != ""
  or
  value = ann.getAStringArrayValue(attr) and
  value != ""
}

/**
 * 读取 Class 或 Class[] 属性对应类型的包名。
 *
 * 例如：
 * - @ComponentScan(basePackageClasses = Marker.class)
 * - @SpringBootApplication(scanBasePackageClasses = Marker.class)
 */
private predicate getAnnotationTypeOrTypeArrayPackage(Annotation ann, string attr, string pkg) {
  exists(RefType marker |
    marker = ann.getTypeValue(attr) and
    pkg = marker.getPackage().getName()
  )
  or
  exists(RefType marker |
    marker = ann.getATypeArrayValue(attr) and
    pkg = marker.getPackage().getName()
  )
}

/**
 * @ComponentScan 显式配置的扫描根包。
 */
private predicate getExplicitComponentScanBasePackage(RefType configType, string pkg) {
  exists(Annotation scan |
    getDeclaredComponentScanAnnotation(configType, scan) and
    (
      getAnnotationStringOrStringArrayValue(scan, "value", pkg)
      or
      getAnnotationStringOrStringArrayValue(scan, "basePackages", pkg)
      or
      getAnnotationTypeOrTypeArrayPackage(scan, "basePackageClasses", pkg)
    )
  )
}

/**
 * @SpringBootApplication 显式配置的扫描根包。
 */
private predicate getExplicitSpringBootScanBasePackage(RefType configType, string pkg) {
  exists(Annotation ann |
    ann = configType.getAnAnnotation() and
    isSpringBootApplicationAnnotation(ann) and
    (
      getAnnotationStringOrStringArrayValue(ann, "scanBasePackages", pkg)
      or
      getAnnotationTypeOrTypeArrayPackage(ann, "scanBasePackageClasses", pkg)
    )
  )
}

/**
 * 是否是声明 component scan 的配置类。
 */
private predicate declaresComponentScan(RefType configType) {
  exists(Annotation scan | getDeclaredComponentScanAnnotation(configType, scan))
  or
  exists(Annotation ann |
    ann = configType.getAnAnnotation() and
    isSpringBootApplicationAnnotation(ann)
  )
}

/**
 * 统一后的扫描根包。
 *
 * 规则：
 * - 如果显式声明 base package，则使用显式值；
 * - 否则 @ComponentScan / @SpringBootApplication 默认扫描声明类所在包。
 */
private predicate getComponentScanBasePackage(RefType configType, string pkg) {
  getExplicitComponentScanBasePackage(configType, pkg)
  or
  getExplicitSpringBootScanBasePackage(configType, pkg)
  or
  (
    declaresComponentScan(configType) and
    not exists(string explicitPkg |
      getExplicitComponentScanBasePackage(configType, explicitPkg)
      or getExplicitSpringBootScanBasePackage(configType, explicitPkg)
    ) and
    pkg = configType.getPackage().getName()
  )
}

/**
 * 判断类型 t 是否位于 basePkg 或其子包下。
 *
 * 注意：
 * 不能写成 pkg.matches(basePkg + ".%") 的独立字符串谓词，
 * 因为 CodeQL 不会从无限 string 空间中枚举 pkg/basePkg。
 * 这里用 RefType 和 getComponentScanBasePackage(...) 先把两边绑定到有限程序实体/注解值。
 */
private predicate typeIsUnderScanBasePackage(RefType t, string basePkg) {
  exists(RefType configType, string candidatePkg |
    getComponentScanBasePackage(configType, basePkg) and
    candidatePkg = t.getPackage().getName() and
    (
      candidatePkg = basePkg
      or
      candidatePkg.matches(basePkg + ".%")
    )
  )
}

private predicate hasAnyComponentScanConfiguration() {
  exists(RefType configType, string basePkg |
    getComponentScanBasePackage(configType, basePkg)
  )
}

/**
 * 某类型是否处于任意 component scan 范围内。
 *
 * 如果数据库里没有发现 @SpringBootApplication / @ComponentScan，
 * 则不强行限制包范围，避免误杀测试代码或非标准项目。
 */
private predicate isInsideComponentScanScope(RefType t) {
  not hasAnyComponentScanConfiguration()
  or
  exists(RefType configType, string basePkg |
    getComponentScanBasePackage(configType, basePkg) and
    typeIsUnderScanBasePackage(t, basePkg)
  )
}

/**
 * @ComponentScan.Filter 的 type 判断。
 */
private predicate componentScanFilterHasType(Annotation filter, string typeName) {
  filter.getEnumConstantValue("type").hasName(typeName)
}

/**
 * 读取 @ComponentScan.Filter(value/classes = Some.class)。
 */
private predicate getComponentScanFilterTypeValue(Annotation filter, RefType t) {
  t = filter.getTypeValue("value")
  or
  t = filter.getATypeArrayValue("value")
  or
  t = filter.getTypeValue("classes")
  or
  t = filter.getATypeArrayValue("classes")
}

/**
 * 低成本 excludeFilters 支持：
 *
 * 1. ANNOTATION:
 *    @ComponentScan(excludeFilters =
 *      @Filter(type = FilterType.ANNOTATION, classes = Deprecated.class))
 *
 * 2. ASSIGNABLE_TYPE:
 *    @ComponentScan(excludeFilters =
 *      @Filter(type = FilterType.ASSIGNABLE_TYPE, classes = FooService.class))
 */
private predicate isExcludedByComponentScanFilter(RefType candidate) {
  exists(RefType configType, Annotation scan, Annotation filter |
    getDeclaredComponentScanAnnotation(configType, scan) and
    filter = scan.getAnArrayValue("excludeFilters") and
    (
      exists(RefType excludedAnn, Annotation ann |
        componentScanFilterHasType(filter, "ANNOTATION") and
        getComponentScanFilterTypeValue(filter, excludedAnn) and
        ann = candidate.getAnAnnotation() and
        ann.getType() = excludedAnn
      )
      or
      exists(RefType excludedType |
        componentScanFilterHasType(filter, "ASSIGNABLE_TYPE") and
        getComponentScanFilterTypeValue(filter, excludedType) and
        (
          candidate = excludedType
          or candidate.getAStrictAncestor() = excludedType
        )
      )
    )
  )
}

/**
 * 直接 Spring stereotype。
 */
private predicate isDirectSpringBeanStereotype(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.stereotype", "Controller")
  or ann.getType().hasQualifiedName("org.springframework.stereotype", "Service")
  or ann.getType().hasQualifiedName("org.springframework.stereotype", "Component")
  or ann.getType().hasQualifiedName("org.springframework.stereotype", "Repository")
}

/**
 * 元注解 stereotype。
 *
 * 支持：
 * - @RestController 这种 Spring 自带组合注解
 * - 用户自定义：
 *
 *   @Component
 *   public @interface UseCase {}
 *
 *   @UseCase
 *   class OrderUseCase {}
 */
private predicate annotationTypeHasComponentMetaAnnotation(RefType annType) {
  exists(Annotation meta |
    meta = annType.getAnAnnotation() and
    (
      meta.getType().hasQualifiedName("org.springframework.stereotype", "Component")
      or annotationTypeHasComponentMetaAnnotation(meta.getType())
    )
  )
}

/**
 * 默认 component scan 可发现的候选组件注解。
 */
private predicate isSpringBeanStereotype(Annotation ann) {
  isDirectSpringBeanStereotype(ann)
  or annotationTypeHasComponentMetaAnnotation(ann.getType())
}

/**
 * 组件扫描得到的 bean 类型。
 */
private predicate isComponentScannedBeanType(RefType t) {
  exists(Annotation ann |
    ann = t.getAnAnnotation() and
    isSpringBeanStereotype(ann)
  ) and
  isInsideComponentScanScope(t) and
  not isExcludedByComponentScanFilter(t)
}

/** -----------------------------
 * Bean stereotypes
 * ----------------------------- */
private predicate isBeanProducedType(RefType t) {
  exists(Method m |
    isBeanFactoryMethod(m) and
    getBeanFactoryProducedType(m, t)
  )
}

/**
 * 统一 Spring bean 类型：
 *
 * 1. component scan 可扫描到的 stereotype / meta-stereotype 类型；
 * 2. @Configuration 类中 @Bean 方法产出的类型。
 *
 * 注意：
 * - @Bean 方法本身不依赖 component scan 包范围；
 * - @Profile / @Conditional 只记录为限制，不在这里精确裁剪。
 */
predicate isSpringBeanType(RefType t) {
  isComponentScannedBeanType(t)
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

/* -----------------------------
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