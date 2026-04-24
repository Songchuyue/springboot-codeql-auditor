import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController
import common.CommonTaintSteps
import common.SpringBindingSources

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

predicate isProjectXssFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  isCommonStringAssemblyStep(pred, succ)
  or
  isSpringBoundObjectPropertyReadStep(pred, succ)
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