/**
 * @name SpringBoot unsafe file upload (filename/path pollution)
 * @description User-controlled uploaded filename reaches file-system path construction or write destination.
 * @kind path-problem
 * @problem.severity warning
 * @security-severity 6.8
 * @precision medium
 * @id scy/java/unsafe-file-upload
 * @tags security
 * external/cwe/cwe-022
 * external/cwe/cwe-073
 * external/cwe/cwe-434
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import UnsafeFileUploadLib

module SpringUnsafeFileUploadConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    isUnsafeUploadSourceNode(src)
  }

  predicate isSink(DataFlow::Node sink) {
    isUnsafeUploadSinkNode(sink)
  }

  predicate isBarrier(DataFlow::Node node) {
    isUnsafeUploadGuardBarrierNode(node)
  }

  predicate isBarrierIn(DataFlow::Node node) {
    isSource(node)
  }

  predicate isAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
    isUnsafeUploadAdditionalFlowStep(pred, succ)
  }
}

module SpringUnsafeFileUploadFlow = TaintTracking::Global<SpringUnsafeFileUploadConfig>;
import SpringUnsafeFileUploadFlow::PathGraph

from SpringUnsafeFileUploadFlow::PathNode source, SpringUnsafeFileUploadFlow::PathNode sink
where SpringUnsafeFileUploadFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "User-controlled uploaded filename reaches file-system path construction or write destination."