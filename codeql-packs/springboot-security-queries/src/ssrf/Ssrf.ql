/**
 * @name SpringBoot SSRF
 * @description Spring MVC user input reaches an outgoing request target.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.1
 * @precision high
 * @id scy/java/ssrf
 * @tags security
 *       external/cwe/cwe-918
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.security.RequestForgery
import SsrfLib
import WebRequestSources

module SpringSsrfConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    isAnyWebInputSourceNode(src)
  }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof RequestForgerySink or
    isProjectSsrfSink(sink)
  }

  predicate isBarrier(DataFlow::Node node) {
    node instanceof RequestForgerySanitizer or
    isProjectSsrfSanitizer(node)
  }

  predicate isBarrierIn(DataFlow::Node node) {
    isSource(node)
  }

  predicate isAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
    any(RequestForgeryAdditionalTaintStep s).propagatesTaint(pred, succ) or
    isProjectSsrfFlowStep(pred, succ)
  }
}

module SpringSsrfFlow = TaintTracking::Global<SpringSsrfConfig>;
import SpringSsrfFlow::PathGraph

from SpringSsrfFlow::PathNode source, SpringSsrfFlow::PathNode sink
where
  SpringSsrfFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Spring MVC input reaches an outgoing request target."