/**
 * @name SpringBoot log injection
 * @description Spring MVC user input reaches a log message without suitable log-injection sanitization.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.8
 * @precision high
 * @id scy/java/log-injection
 * @tags security
 *       external/cwe/cwe-117
 */

import java

import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.security.LogInjection
import LogInjectionLib
import WebRequestSources

module SpringLogInjectionConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    isAnyWebInputSourceNode(src)
  }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof LogInjectionSink or
    isProjectLogInjectionSink(sink)
  }

  predicate isBarrier(DataFlow::Node node) {
    node instanceof LogInjectionSanitizer or
    isProjectLogInjectionSanitizer(node)
  }

  predicate isBarrierIn(DataFlow::Node node) {
    isSource(node)
  }

  predicate isAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
    any(LogInjectionAdditionalTaintStep s).step(pred, succ) or
    isProjectLogInjectionFlowStep(pred, succ)
  }
}

module SpringLogInjectionFlow = TaintTracking::Global<SpringLogInjectionConfig>;

import SpringLogInjectionFlow::PathGraph

from SpringLogInjectionFlow::PathNode source, SpringLogInjectionFlow::PathNode sink
where SpringLogInjectionFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Spring MVC input reaches a log message without log-injection sanitization."