import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.security.LogInjection
import semmle.code.java.security.XSS
import common.CommonTaintSteps
import common.SensitiveDataSources
import common.ProjectLogging

predicate isSensitiveExposureSourceNode(DataFlow::Node src) {
  isSensitiveDataSourceNode(src)
}

predicate isSensitiveExposureAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  isCommonStringAssemblyStep(pred, succ)
}

private predicate isResponseLikeGetWriter(MethodCall getWriter) {
  getWriter.getMethod().hasName("getWriter") and
  exists(RefType t |
    t = getWriter.getMethod().getDeclaringType() and
    (
      t.hasQualifiedName("jakarta.servlet.http", "HttpServletResponse") or
      t.hasQualifiedName("javax.servlet.http", "HttpServletResponse") or
      t.getName().matches("%Response%")
    )
  )
}

class ResponseLikeWriteSink extends DataFlow::ExprNode {
  ResponseLikeWriteSink() {
    exists(MethodCall out, MethodCall getWriter |
      (
        out.getMethod().hasName("write") or
        out.getMethod().hasName("print") or
        out.getMethod().hasName("println")
      ) and
      getWriter = out.getQualifier() and
      isResponseLikeGetWriter(getWriter) and
      this.asExpr() = out.getArgument(0)
    )
  }
}

predicate isSensitiveExposureSinkNode(DataFlow::Node sink) {
  sink instanceof LogInjectionSink or
  isProjectLogInjectionSink(sink) or
  sink instanceof XssSink or
  sink instanceof ResponseLikeWriteSink
}