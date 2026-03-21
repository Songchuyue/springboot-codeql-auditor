/**
 * @name SpringBoot path traversal
 * @description Spring MVC user input reaches a file-system access path.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision high
 * @id scy/java/path-traversal
 * @tags security
 * external/cwe/cwe-022
 * external/cwe/cwe-023
 * external/cwe/cwe-036
 * external/cwe/cwe-073
 */

import java

import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.security.TaintedPathQuery
import PathTraversalLib
import WebRequestSources

module SpringPathTraversalConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    isAnyWebInputSourceNode(src)
  }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof TaintedPathSink or
    isProjectPathTraversalSink(sink)
  }

  predicate isBarrier(DataFlow::Node node) {
    isProjectPathTraversalSanitizer(node)
  }

  predicate isAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
    any(TaintedPathAdditionalTaintStep s).step(pred, succ) or
    isProjectPathTraversalFlowStep(pred, succ)
  }
}

module SpringPathTraversalFlow = TaintTracking::Global<SpringPathTraversalConfig>;

import SpringPathTraversalFlow::PathGraph

from SpringPathTraversalFlow::PathNode source, SpringPathTraversalFlow::PathNode sink
where SpringPathTraversalFlow::flowPath(source, sink)
select sink.getNode().asExpr(), source, sink,
  "Spring MVC input reaches a file-system access path."