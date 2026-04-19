/**
 * @name SpringBoot sensitive data exposure
 * @description Sensitive data reaches project logs or response-like output.
 * @kind path-problem
 * @problem.severity warning
 * @security-severity 6.5
 * @precision medium
 * @id scy/java/sensitive-data-exposure
 * @tags security
 * external/cwe/cwe-200
 * external/cwe/cwe-532
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import SensitiveDataExposureLib

module SpringSensitiveDataExposureConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    isSensitiveExposureSourceNode(src)
  }

  predicate isSink(DataFlow::Node sink) {
    isSensitiveExposureSinkNode(sink)
  }

  predicate isAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
    isSensitiveExposureAdditionalFlowStep(pred, succ)
  }
}

module SpringSensitiveDataExposureFlow =
  TaintTracking::Global<SpringSensitiveDataExposureConfig>;

import SpringSensitiveDataExposureFlow::PathGraph

from SpringSensitiveDataExposureFlow::PathNode source, SpringSensitiveDataExposureFlow::PathNode sink
where SpringSensitiveDataExposureFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Sensitive data reaches a project log sink or response-like output."