import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.security.LogInjection
import semmle.code.java.security.XSS

import common.CommonTaintSteps
import common.SensitiveDataSources
import common.ProjectLogging
import common.SpringBeanModel

predicate isSensitiveExposureSourceNode(DataFlow::Node src) {
  isSensitiveDataSourceNode(src)
}

predicate isSensitiveExposureAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  isCommonStringAssemblyStep(pred, succ)
}

bindingset[n]
private predicate desensitizeLikeMethodName(string n) {
  n.matches("mask%") or
  n.matches("redact%") or
  n.matches("desensit%") or
  n.matches("sanitize%") or
  n.matches("obfuscat%") or
  n.matches("hide%")
}

private predicate desensitizeLikeType(RefType t) {
  t.getName().matches("%Mask%") or
  t.getName().matches("%Redact%") or
  t.getName().matches("%Desensit%") or
  t.getName().matches("%Sanit%") or
  t.getName().matches("%Obfuscat%")
}

private predicate isDirectDesensitizeCall(MethodCall mc) {
  desensitizeLikeMethodName(mc.getMethod().getName()) and
  desensitizeLikeType(mc.getMethod().getDeclaringType())
}

private predicate isInjectedDesensitizeCall(MethodCall mc) {
  desensitizeLikeMethodName(mc.getMethod().getName()) and
  exists(RefType impl |
    injectedFieldReceiverCallMayResolveToBeanType(mc, impl) and
    desensitizeLikeType(impl)
  )
}

predicate isSensitiveExposureSanitizerNode(DataFlow::Node node) {
  exists(MethodCall mc |
    node = DataFlow::exprNode(mc) and
    (isDirectDesensitizeCall(mc) or isInjectedDesensitizeCall(mc))
  )
}

private predicate isHttpServletResponseGetWriter(MethodCall getWriter) {
  getWriter.getMethod().hasName("getWriter") and
  exists(RefType t |
    t = getWriter.getMethod().getDeclaringType() and
    (
      t.hasQualifiedName("jakarta.servlet.http", "HttpServletResponse") or
      t.hasQualifiedName("javax.servlet.http", "HttpServletResponse")
    )
  )
}

class HttpServletResponseWriteSink extends DataFlow::ExprNode {
  HttpServletResponseWriteSink() {
    exists(MethodCall out, MethodCall getWriter |
      (
        out.getMethod().hasName("write") or
        out.getMethod().hasName("print") or
        out.getMethod().hasName("println")
      ) and
      getWriter = out.getQualifier() and
      isHttpServletResponseGetWriter(getWriter) and
      this.asExpr() = out.getArgument(0)
    )
  }
}

predicate isSensitiveExposureSinkNode(DataFlow::Node sink) {
  sink instanceof LogInjectionSink or
  isProjectLogInjectionSink(sink) or
  sink instanceof XssSink or
  sink instanceof HttpServletResponseWriteSink
}