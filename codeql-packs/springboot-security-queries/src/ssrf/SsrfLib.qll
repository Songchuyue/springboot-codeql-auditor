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

// RestClient restClient = RestClient.create(baseUrl);
// restClient.get().uri(...).retrieve().body(...);// 虽然uri不由用户控制, 但用户控制了baseUrl, 故依然算sink
private predicate isRestClientCreateWithBaseUrl(Method m) {
  m.hasQualifiedName("org.springframework.web.client", "RestClient", "create") and
  m.getNumberOfParameters() = 1 and
  (
    isStringType(m.getParameter(0).getType()) or
    isUriType(m.getParameter(0).getType())
  )
}

// RestClient restClient = RestClient.builder().baseUrl(baseUrl);
// restClient.get().uri(...).retrieve().body(...);
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
 * RestClient.create(baseUrl)和RestClient.builder().baseUrl(baseUrl)本质都是复用了RestTemplate
 * 前者是根据baseUrl直接创建RestClient对象, 后者是通过builder允许你指定部分参数(即不止baseUrl)
 */

// 直接控制请求目标, 分为RestClient.create(baseUrl), RestClient.builder.baseUrl(baseUrl), restClient.get().uri(...)
private class RestClientDirectTargetSink extends RequestForgerySink {
  RestClientDirectTargetSink() {
    exists(MethodCall mc |
      this.asExpr() = mc.getArgument(0) and
      (
        isRestClientCreateWithBaseUrl(mc.getMethod()) or// RestClient.create(baseUrl)
        isRestClientBuilderBaseUrlMethod(mc.getMethod()) or// RestClient.builder.baseUrl(baseUrl)
        (
          isRestClientUriMethod(mc.getMethod()) and// 匹配uri方法
          mc.getMethod().getNumberOfParameters() >= 1 and// 仅一个参数的情况(多参数属于下面的UriVariables)
          (
            isStringType(mc.getMethod().getParameter(0).getType()) or// restClient.get().uri(url)
            isUriType(mc.getMethod().getParameter(0).getType())// restClient.get().uri(uriObj)
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

  int getUriVariablesPosition() { result = pos }// pos记录了uriVariables位置
}

// 取出URI模板, 如restClient.get().uri("http://{host}/internal", host), 则取出"http://{host}/internal"
pragma[inline]// 内联展开
private CompileTimeConstantExpr getConstantUrl(MethodCall mc) {// 使用CompileTimeConstantExpr确定返回值类型
  result = mc.getArgument(0)
}

// 找placeholder, 其中idx表示placeholder的次序, offset表示某placeholder对应的偏移量
pragma[inline]
private predicate urlHasPlaceholderAtOffset(MethodCall mc, int idx, int offset) {
  exists(string url, string placeholder |
    url = getConstantUrl(mc).getStringValue() and
    placeholder = url.regexpFind("\\{[^}]+\\}", idx, offset)// "\\{" = 匹配'{', "[^}]+" = 匹配若干个非'}'字符, "\\}" = 匹配'}'
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

// ------------------------------
// RequestEntity / RestTemplate.exchange(RequestEntity, ...)
// ------------------------------

private predicate isRequestEntityType(Type t) {
  exists(RefType rt |
    rt = t and
    rt.hasQualifiedName("org.springframework.http", "RequestEntity")
  )
}

// RequestEntity.get()/.head()/.post()/.delete()/.method()返回的是builder, 再链式设置header/body, 最后通过.body()转为RequestEntity
private predicate isRequestEntityBuilderType(Type t) {
  exists(RefType rt |
    rt = t and
    (
      rt.hasQualifiedName("org.springframework.http", "RequestEntity$HeadersBuilder") or
      rt.hasQualifiedName("org.springframework.http", "RequestEntity$BodyBuilder")
    )
  )
}

// RequestEntity.get()/.head()/.post()/.delete()/.method()精准匹配这些方法
private predicate isRequestEntityStaticBuilder(Method m) {
  m.isStatic() and
  m.getDeclaringType().hasQualifiedName("org.springframework.http", "RequestEntity") and
  isRequestEntityBuilderType(m.getReturnType())
}


// 通过pos定位String或者Uri参数
private predicate isRequestEntityStringOrUriTargetParameter(Method m, int pos) {
  isRequestEntityStaticBuilder(m) and
  (
    isStringType(m.getParameter(pos).getType()) or
    isUriType(m.getParameter(pos).getType())
  )
}

// 通过pos定位Uri参数
private predicate isRequestEntityStringTargetParameter(Method m, int pos) {
  isRequestEntityStaticBuilder(m) and
  isStringType(m.getParameter(pos).getType())
}

// 直接控制 RequestEntity 目标：
// 1. new RequestEntity(..., URI)
// 2. RequestEntity.get(URI) / method(..., URI)
// 3. RequestEntity.get("http://...") / method(..., "http://...")
private class RequestEntityDirectTargetSink extends RequestForgerySink {
  RequestEntityDirectTargetSink() {
    exists(Method m, MethodCall mc, int i |
      mc.getMethod() = m and
      isRequestEntityStringOrUriTargetParameter(m, i) and
      this.asExpr() = mc.getArgument(i)
    )
    or
    exists(ClassInstanceExpr cie, int i |
      isRequestEntityType(cie.getConstructedType()) and
      isUriType(cie.getConstructor().getParameter(i).getType()) and
      this.asExpr() = cie.getArgument(i)
    )
  }
}

// 匹配 RequestEntity.get("http://{host}/internal", host) 这类带 uriVariables 的 builder
private class RequestEntityBuilderMethodWithUriVariablesParameter extends Method {
  int pos;
  RequestEntityBuilderMethodWithUriVariablesParameter() {
    isRequestEntityStaticBuilder(this) and
    this.getParameter(pos).getName() = "uriVariables"
  }
  int getUriVariablesPosition() { result = pos }
}

pragma[inline]
private CompileTimeConstantExpr getRequestEntityConstantUrl(MethodCall mc) {
  exists(int i |
    isRequestEntityStringTargetParameter(mc.getMethod(), i) and
    result = mc.getArgument(i)
  )
}

pragma[inline]
private predicate requestEntityUrlHasPlaceholderAtOffset(MethodCall mc, int idx, int offset) {
  exists(string url, string placeholder |
    url = getConstantUrl(mc).getStringValue() and
    placeholder = url.regexpFind("\\{[^}]+\\}", idx, offset)// "\\{" = 匹配'{', "[^}]+" = 匹配若干个非'}'字符, "\\}" = 匹配'}'
  )
}

private class RequestEntityUriVariableSink extends RequestForgerySink {
  RequestEntityUriVariableSink() {
    exists(RequestEntityBuilderMethodWithUriVariablesParameter m, MethodCall mc, int i |
      mc.getMethod() = m and
      i >= 0 and
      this.asExpr() = mc.getArgument(m.getUriVariablesPosition() + i) and
      (
        exists(int offset |
          requestEntityUrlHasPlaceholderAtOffset(mc, i, offset) and
          offset < getRequestEntityConstantUrl(mc).(HostnameSanitizingPrefix).getOffset()
        )
        or
        (
          not getRequestEntityConstantUrl(mc) instanceof HostnameSanitizingPrefix and
          requestEntityUrlHasPlaceholderAtOffset(mc, i, _)
        )
        or
        not exists(getRequestEntityConstantUrl(mc).getStringValue())
      )
    )
  }
}

predicate isProjectSsrfSink(DataFlow::Node sink) {
  sink instanceof RestClientDirectTargetSink or
  sink instanceof RestClientUriVariableSink or
  sink instanceof RequestEntityDirectTargetSink or
  sink instanceof RequestEntityUriVariableSink
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