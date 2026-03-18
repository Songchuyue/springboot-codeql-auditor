import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController

predicate isOfficialSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
}

/**
 * 第一阶段先不额外补 sink。
 * 官方 XssSink 先覆盖 response.getWriter().print/write/println 这类最稳场景。
 * 后续如果你要补 @ResponseBody 返回 HTML / Thymeleaf th:utext，再在这里扩。
 */
predicate isProjectXssSink(DataFlow::Node sink) {
  none()
}

private predicate isBuilderType(RefType t) {
  t.hasQualifiedName("java.lang", "StringBuilder") or
  t.hasQualifiedName("java.lang", "StringBuffer")
}

private predicate isBuilderAppendMethod(Method m) {
  m.hasName("append") and
  exists(RefType t |
    t = m.getDeclaringType() and
    isBuilderType(t)
  )
}

private predicate isBuilderToStringMethod(Method m) {
  m.hasName("toString") and
  exists(RefType t |
    t = m.getDeclaringType() and
    isBuilderType(t)
  )
}

private predicate isStringFormatMethod(Method m) {
  m.hasQualifiedName("java.lang", "String", "format")
}

/**
 * 项目级额外传播：
 * 1. StringBuilder / StringBuffer.append(...)
 * 2. builder.toString()
 * 3. String.format(...)
 */
predicate isProjectXssFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  exists(MethodCall mc, DataFlow::PostUpdateNode post |
    isBuilderAppendMethod(mc.getMethod()) and
    pred = DataFlow::exprNode(mc.getArgument(0)) and
    post.getPreUpdateNode() = DataFlow::exprNode(mc.getQualifier()) and
    succ = post
  )
  or
  exists(MethodCall mc, DataFlow::PostUpdateNode post |
    isBuilderAppendMethod(mc.getMethod()) and
    pred = post.getPreUpdateNode() and
    post.getPreUpdateNode() = DataFlow::exprNode(mc.getQualifier()) and
    succ = post
  )
  or
  exists(MethodCall mc |
    isBuilderToStringMethod(mc.getMethod()) and
    pred = DataFlow::exprNode(mc.getQualifier()) and
    succ = DataFlow::exprNode(mc)
  )
  or
  exists(MethodCall mc, int i |
    isStringFormatMethod(mc.getMethod()) and
    succ = DataFlow::exprNode(mc) and
    (
      mc.getMethod().getNumberOfParameters() = 2 and
      i >= 1 and
      pred = DataFlow::exprNode(mc.getArgument(i))
      or
      mc.getMethod().getNumberOfParameters() = 3 and
      i >= 2 and
      pred = DataFlow::exprNode(mc.getArgument(i))
    )
  )
}

/**
 * 项目级 sanitizer：
 * 只认“真正做了输出编码/转义”的 API。
 */
predicate isProjectXssSanitizer(DataFlow::Node node) {
  exists(MethodCall mc |
    node = DataFlow::exprNode(mc) and
    (
      mc.getMethod().hasQualifiedName("org.springframework.web.util", "HtmlUtils", "htmlEscape") or
      mc.getMethod().hasQualifiedName("org.springframework.web.util", "HtmlUtils", "htmlEscapeHex") or

      mc.getMethod().hasQualifiedName("org.apache.commons.text", "StringEscapeUtils", "escapeHtml4") or
      mc.getMethod().hasQualifiedName("org.apache.commons.text", "StringEscapeUtils", "escapeHtml3") or

      mc.getMethod().hasQualifiedName("org.apache.commons.lang3", "StringEscapeUtils", "escapeHtml4") or
      mc.getMethod().hasQualifiedName("org.apache.commons.lang3", "StringEscapeUtils", "escapeHtml3") or

      mc.getMethod().hasQualifiedName("org.owasp.encoder", "Encode", "forHtml") or
      mc.getMethod().hasQualifiedName("org.owasp.encoder", "Encode", "forHtmlContent") or
      mc.getMethod().hasQualifiedName("org.owasp.encoder", "Encode", "forHtmlAttribute")
    )
  )
}