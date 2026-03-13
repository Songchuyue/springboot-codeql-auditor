import java
import semmle.code.java.controlflow.Guards
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController
import semmle.code.java.security.RequestForgery

private predicate isFallbackSpringControllerAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RestController") or
  ann.getType().hasQualifiedName("org.springframework.stereotype", "Controller")
}

private predicate isFallbackSpringRequestHandlerAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RequestMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "GetMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "PostMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "PutMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "DeleteMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "PatchMapping")
}

private predicate isFallbackSpringMvcParameterAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RequestParam") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "PathVariable") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RequestHeader") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "CookieValue") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "MatrixVariable") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RequestBody")
}

private predicate isFallbackAnnotatedSpringMvcSourceNode(DataFlow::Node src) {
  exists(Parameter p, Method m |
    src = DataFlow::parameterNode(p) and
    p.fromSource() and
    m = p.getCallable() and
    exists(Annotation cAnn |
      cAnn = m.getDeclaringType().getAnAnnotation() and
      isFallbackSpringControllerAnnotation(cAnn)
    ) and
    exists(Annotation mAnn |
      mAnn = m.getAnAnnotation() and
      isFallbackSpringRequestHandlerAnnotation(mAnn)
    ) and
    exists(Annotation pAnn |
      pAnn = p.getAnAnnotation() and
      isFallbackSpringMvcParameterAnnotation(pAnn)
    )
  )
}

private predicate isOfficialSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
}

predicate isSpringMvcSourceNode(DataFlow::Node src) {
  isOfficialSpringMvcSourceNode(src)
  or
  isFallbackAnnotatedSpringMvcSourceNode(src)
}

private predicate isStringType(Type t) {
  exists(RefType rt |
    rt = t and
    rt.hasQualifiedName("java.lang", "String")
  )
}

private predicate isUriType(Type t) {
  exists(RefType rt |
    rt = t and
    rt.hasQualifiedName("java.net", "URI")
  )
}

private predicate isRestClientUriSpecType(RefType t) {
  t.hasQualifiedName("org.springframework.web.client", "RestClient$UriSpec") or
  t.hasQualifiedName("org.springframework.web.client", "RestClient$RequestHeadersUriSpec") or
  t.hasQualifiedName("org.springframework.web.client", "RestClient$RequestBodyUriSpec")
}

private predicate isRestClientUriMethod(Method m) {
  m.hasName("uri") and
  exists(RefType t |
    t = m.getDeclaringType() and
    isRestClientUriSpecType(t)
  )
}

private predicate isRestClientCreateWithBaseUrl(Method m) {
  m.hasQualifiedName("org.springframework.web.client", "RestClient", "create") and
  m.getNumberOfParameters() = 1 and
  (
    isStringType(m.getParameter(0).getType()) or
    isUriType(m.getParameter(0).getType())
  )
}

private predicate isRestClientBuilderBaseUrlMethod(Method m) {
  exists(RefType t |
    t = m.getDeclaringType() and
    t.hasQualifiedName("org.springframework.web.client", "RestClient$Builder")
  ) and
  m.hasName("baseUrl") and
  m.getNumberOfParameters() = 1 and
  (
    isStringType(m.getParameter(0).getType()) or
    isUriType(m.getParameter(0).getType())
  )
}

/**
 * 直接控制请求目标：
 *   RestClient.create(baseUrl)
 *   RestClient.builder().baseUrl(baseUrl)
 *   client.get().uri(url)
 *   client.get().uri(uri)
 *   client.get().uri("http://{host}/x", host) 的第一个参数
 */
private class RestClientDirectTargetSink extends RequestForgerySink {
  RestClientDirectTargetSink() {
    exists(MethodCall mc |
      this.asExpr() = mc.getArgument(0) and
      (
        isRestClientCreateWithBaseUrl(mc.getMethod()) or
        isRestClientBuilderBaseUrlMethod(mc.getMethod()) or
        (
          isRestClientUriMethod(mc.getMethod()) and
          mc.getMethod().getNumberOfParameters() >= 1 and
          (
            isStringType(mc.getMethod().getParameter(0).getType()) or
            isUriType(mc.getMethod().getParameter(0).getType())
          )
        )
      )
    )
  }
}

/**
 * 模板变量控制请求目标：
 *   client.get().uri("http://{host}/internal", host)
 *   client.get().uri("http://x/{id}", map)
 *
 * 这里基本照着官方对 RestTemplate uriVariables 的建模思路来。
 */
private class RestClientUriMethodWithUriVariablesParameter extends Method {
  int pos;
  RestClientUriMethodWithUriVariablesParameter() {
    isRestClientUriMethod(this) and
    this.getParameter(pos).getName() = "uriVariables"
  }

  int getUriVariablesPosition() { result = pos }
}

pragma[inline]
private CompileTimeConstantExpr getConstantUrl(MethodCall mc) {
  result = mc.getArgument(0)
}

pragma[inline]
private predicate urlHasPlaceholderAtOffset(MethodCall mc, int idx, int offset) {
  exists(
    getConstantUrl(mc).getStringValue()
      .replaceAll("\\{", " ")
      .replaceAll("\\}", " ")
      .regexpFind("\\{[^}]*\\}", idx, offset)
  )
}

private class RestClientUriVariableSink extends RequestForgerySink {
  RestClientUriVariableSink() {
    exists(RestClientUriMethodWithUriVariablesParameter m, MethodCall mc, int i |
      mc.getMethod() = m and
      i >= 0 and
      this.asExpr() = mc.getArgument(m.getUriVariablesPosition() + i) and
      (
        exists(int offset |
          urlHasPlaceholderAtOffset(mc, i, offset) and
          offset < getConstantUrl(mc).(HostnameSanitizingPrefix).getOffset()
        )
        or
        (
          not getConstantUrl(mc) instanceof HostnameSanitizingPrefix and
          urlHasPlaceholderAtOffset(mc, i, _)
        )
        or
        not exists(getConstantUrl(mc).getStringValue())
      )
    )
  }
}

predicate isProjectSsrfSink(DataFlow::Node sink) {
  sink instanceof RestClientDirectTargetSink or
  sink instanceof RestClientUriVariableSink
}

predicate assertAllowedGuard(Guard g, Expr e, boolean branch) {
  exists(MethodCall mc |
    mc.getMethod().hasQualifiedName("java.lang", "String", "equals") and
    g = mc and
    e = mc.getArgument(0) and
    branch = true
  )
}

/** Extension point for project-specific SSRF sanitizers. */
predicate isProjectSsrfSanitizer(DataFlow::Node node) { 
  node = DataFlow::BarrierGuard<assertAllowedGuard/3>::getABarrierNode()
 }

/** Extension point for project-specific SSRF extra taint steps. */
predicate isProjectSsrfFlowStep(DataFlow::Node pred, DataFlow::Node succ) { none() }