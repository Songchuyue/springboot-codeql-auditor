import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController

/**
 * Lightweight Spring MVC binding model.
 *
 * 目标：
 * 1. 将 @RequestBody / @ModelAttribute / 普通复杂对象参数视为 Spring MVC 绑定对象。
 * 2. 不把 BindingResult、HttpServletRequest、HttpServletResponse 等框架对象当成业务 DTO。
 * 3. 建模 “DTO 对象 -> getter/字段访问结果” 的污点传播。
 *
 * 注意：
 * - @Valid 只说明发生校验，不等于 sanitizer。
 * - BindingResult 只说明接收校验结果，不等于 sanitizer。
 * - 该模型是高召回轻量建模，不做 BeanWrapper/Jackson 内部完整模拟。
 */

private predicate hasAnnotationWithName(Annotatable a, string name) {
  exists(Annotation ann |
    ann = a.getAnAnnotation() and
    ann.getType().hasName(name)
  )
}

private predicate isPackageOrSubPackage(RefType t, string pkgPrefix) {
  exists(string pkg |
    pkg = t.getPackage().getName() and
    (
      pkgPrefix = "java" and
      (pkg = "java" or pkg.matches("java.%"))
      or
      pkgPrefix = "javax.servlet" and
      (pkg = "javax.servlet" or pkg.matches("javax.servlet.%"))
      or
      pkgPrefix = "jakarta.servlet" and
      (pkg = "jakarta.servlet" or pkg.matches("jakarta.servlet.%"))
      or
      pkgPrefix = "org.springframework" and
      (pkg = "org.springframework" or pkg.matches("org.springframework.%"))
      or
      pkgPrefix = "org.slf4j" and
      (pkg = "org.slf4j" or pkg.matches("org.slf4j.%"))
      or
      pkgPrefix = "ch.qos.logback" and
      (pkg = "ch.qos.logback" or pkg.matches("ch.qos.logback.%"))
    )
  )
}

private predicate isStringOrBoxedOrEnum(Type t) {
  exists(RefType rt |
    rt = t and
    (
      rt.hasQualifiedName("java.lang", "String") or
      rt.hasQualifiedName("java.lang", "Integer") or
      rt.hasQualifiedName("java.lang", "Long") or
      rt.hasQualifiedName("java.lang", "Boolean") or
      rt.hasQualifiedName("java.lang", "Double") or
      rt.hasQualifiedName("java.lang", "Float") or
      rt.hasQualifiedName("java.lang", "Short") or
      rt.hasQualifiedName("java.lang", "Byte") or
      rt.hasQualifiedName("java.math", "BigDecimal") or
      rt.hasQualifiedName("java.math", "BigInteger") or
      rt.hasQualifiedName("java.time", "LocalDate") or
      rt.hasQualifiedName("java.time", "LocalDateTime") or
      rt.hasQualifiedName("java.time", "Instant") or
      rt instanceof EnumType
    )
  )
}

private predicate isSpringBindingResultOrErrors(Type t) {
  exists(RefType rt |
    rt = t and
    (
      rt.hasQualifiedName("org.springframework.validation", "BindingResult") or
      rt.hasQualifiedName("org.springframework.validation", "Errors")
    )
  )
}

private predicate isServletOrSpringInfrastructureType(Type t) {
  exists(RefType rt |
    rt = t and
    (
      isPackageOrSubPackage(rt, "javax.servlet") or
      isPackageOrSubPackage(rt, "jakarta.servlet") or
      isPackageOrSubPackage(rt, "org.springframework") or
      isPackageOrSubPackage(rt, "org.slf4j") or
      isPackageOrSubPackage(rt, "ch.qos.logback")
    )
  )
}

private predicate isDtoLikeType(Type t) {
  exists(RefType rt |
    rt = t and
    not isStringOrBoxedOrEnum(t) and
    not isSpringBindingResultOrErrors(t) and
    not isServletOrSpringInfrastructureType(t) and
    not isPackageOrSubPackage(rt, "java")
  )
}

/**
 * Spring MVC 绑定对象参数：
 * - @RequestBody：JSON/Jackson 反序列化绑定对象
 * - @ModelAttribute：表单/query 参数绑定对象
 * - 未显式注解的复杂对象参数：Spring MVC 默认也可能按 model attribute 绑定
 *
 * 这里只限定 SpringRequestMappingParameter，避免把普通 service 方法参数误当入口 source。
 */
predicate isSpringMvcBoundObjectParameter(Parameter p) {
  exists(SpringRequestMappingParameter rp |
    p = rp and
    isDtoLikeType(p.getType()) and
    (
      rp.isTaintedInput() or
      hasAnnotationWithName(p, "RequestBody") or
      hasAnnotationWithName(p, "ModelAttribute") or
      hasAnnotationWithName(p, "Valid") or
      hasAnnotationWithName(p, "Validated")
    )
  )
}

/**
 * DTO 对象本身作为 source。
 *
 * 例：
 *   public void f(@RequestBody UserReq req)
 *
 * 这里 req 被视为 tainted object。
 */
predicate isSpringMvcBoundObjectSourceNode(DataFlow::Node src) {
  exists(Parameter p |
    isSpringMvcBoundObjectParameter(p) and
    src = DataFlow::parameterNode(p)
  )
}

private predicate isGetterLike(Method m) {
  not m.isStatic() and
  m.getNumberOfParameters() = 0 and
  not m.hasName("getClass") and
  (
    m.getName().matches("get%") or
    m.getName().matches("is%")
  )
}

private predicate isReadableDtoField(Field f) {
  not f.isStatic() and
  not f.hasName("serialVersionUID")
}

/**
 * 核心传播边：
 *
 *   dto  -> dto.getName()
 *   dto  -> dto.name
 *
 * 这样 @RequestBody/@ModelAttribute 的字段读取结果会被当成用户输入。
 */
predicate isSpringBoundObjectPropertyReadStep(DataFlow::Node pred, DataFlow::Node succ) {
  exists(MethodCall mc, RefType rt |
    mc.getQualifier().getType() = rt and
    isDtoLikeType(rt) and
    isGetterLike(mc.getMethod()) and
    pred = DataFlow::exprNode(mc.getQualifier()) and
    succ = DataFlow::exprNode(mc)
  )
  or
  exists(FieldAccess fa, RefType rt |
    fa.getQualifier().getType() = rt and
    isDtoLikeType(rt) and
    isReadableDtoField(fa.getField()) and
    pred = DataFlow::exprNode(fa.getQualifier()) and
    succ = DataFlow::exprNode(fa)
  )
}