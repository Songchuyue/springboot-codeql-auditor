/**
 * @name SpringBoot sensitive data exposure
 * @description Sensitive data reaches logs or HTTP response output.
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
import semmle.code.java.security.LogInjection
import semmle.code.java.security.XSS
import SensitiveDataExposureLib

module SpringSensitiveDataExposureConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    isSensitiveExposureSourceNode(src)
  }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof LogInjectionSink or
    sink instanceof XssSink
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
  "Sensitive data reaches a log sink or HTTP response output."