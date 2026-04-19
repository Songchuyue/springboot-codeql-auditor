import java
import semmle.code.java.dataflow.DataFlow
import common.CommonTaintSteps
import common.SensitiveDataSources

predicate isSensitiveExposureSourceNode(DataFlow::Node src) {
  isSensitiveDataSourceNode(src)
}

predicate isSensitiveExposureAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  isCommonStringAssemblyStep(pred, succ)
}