/**
 * @name SpringBoot cross-site scripting
 * @description Spring MVC user input reaches an HTML response sink without contextual output encoding.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id scy/java/xss
 * @tags security
 *       external/cwe/cwe-079
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.security.Sanitizers
import semmle.code.java.security.XSS
import XssLib
import WebRequestSources

module SpringXssConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    isAnyWebInputSourceNode(src)
  }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof XssSink or
    isProjectXssSink(sink)
  }

  predicate isBarrier(DataFlow::Node node) {
    node instanceof SimpleTypeSanitizer or
    node instanceof XssSanitizer or
    isProjectXssSanitizer(node)
  }

  predicate isAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
    any(XssAdditionalTaintStep s).step(pred, succ) or
    isProjectXssFlowStep(pred, succ)
  }
}

module SpringXssFlow = TaintTracking::Global<SpringXssConfig>;
import SpringXssFlow::PathGraph

from SpringXssFlow::PathNode source, SpringXssFlow::PathNode sink
where SpringXssFlow::flowPath(source, sink)
select sink.getNode().asExpr(), source, sink,
  "Spring MVC input reaches an HTML response sink without contextual output encoding."