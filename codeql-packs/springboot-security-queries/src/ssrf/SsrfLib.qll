import java
import semmle.code.java.controlflow.Guards
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController
import semmle.code.java.security.RequestForgery

predicate isOfficialSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
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

// client.get().uri(...), 注意, 这里只是匹配左示例的方法本身, 而不是方法调用
private predicate isRestClientUriMethod(Method m) {
  m.hasName("uri") and
  exists(RefType t |
    t = m.getDeclaringType() and
    isRestClientUriSpecType(t)
  )
}

// RestClient.create(baseUrl)
private predicate isRestClientCreateWithBaseUrl(Method m) {
  m.hasQualifiedName("org.springframework.web.client", "RestClient", "create") and
  m.getNumberOfParameters() = 1 and
  (
    isStringType(m.getParameter(0).getType()) or
    isUriType(m.getParameter(0).getType())
  )
}

// RestClient.builder().baseUrl(baseUrl)
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

// 直接控制请求目标, 分为RestClient.create(baseUrl), RestClient.builder.baseUrl(baseUrl), restClient.get().uri(...)
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


// 匹配uri(..., uriVariables...)这类方法
private class RestClientUriMethodWithUriVariablesParameter extends Method {
  int pos;
  RestClientUriMethodWithUriVariablesParameter() {
    isRestClientUriMethod(this) and// 先找uri方法
    this.getParameter(pos).getName() = "uriVariables"// 再确定uriVariables位置, 注意, 位置下标从0开始
  }

  int getUriVariablesPosition() { result = pos }// 一般来说, uriVariables是连续的, 故可将pos理解为首位uriVariables的位置
}

// 取出URI模板, 如restClient.get().uri("http://{host}/internal", host), 则取出"http://{host}/internal"
pragma[inline]
private CompileTimeConstantExpr getConstantUrl(MethodCall mc) {
  result = mc.getArgument(0)
}

// 找placeholder, 其中idx表示placeholder的次序, offset表示某placeholder对应的偏移量
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
      mc.getMethod() = m and// mc匹配带uriVariables参数的uri方法
      i >= 0 and
      this.asExpr() = mc.getArgument(m.getUriVariablesPosition() + i) and// 匹配uri(..., uriVariables...)的若干uriVariables参数
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