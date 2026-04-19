import java
import semmle.code.java.dataflow.DataFlow
import common.CommonTaintSteps
import common.SensitiveDataSources
import common.ProjectLogging

predicate isSensitiveExposureSourceNode(DataFlow::Node src) {
  isSensitiveDataSourceNode(src)
}

predicate isSensitiveExposureAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  isCommonStringAssemblyStep(pred, succ)
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
      getWriter.getMethod().hasName("getWriter") and
      this.asExpr() = out.getArgument(0)
    )
  }
}

predicate isSensitiveExposureSinkNode(DataFlow::Node sink) {
  isProjectLogInjectionSink(sink) or
  sink instanceof ResponseLikeWriteSink
}