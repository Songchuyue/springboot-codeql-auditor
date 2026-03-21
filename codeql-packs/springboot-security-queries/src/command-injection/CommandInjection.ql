/**
 * @name SpringBoot command injection
 * @description Spring MVC user input reaches OS command execution.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.8
 * @precision high
 * @id scy/java/command-injection
 * @tags security
 * external/cwe/cwe-078
 * external/cwe/cwe-088
 */

import java

import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.security.CommandLineQuery
import CommandInjectionLib
import WebRequestSources

module SpringCommandInjectionConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    isAnyWebInputSourceNode(src)
  }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof CommandInjectionSink or
    isProjectCommandInjectionSink(sink)
  }

  predicate isBarrier(DataFlow::Node node) {
    node instanceof CommandInjectionSanitizer or
    isProjectCommandInjectionSanitizer(node)
  }

  predicate isAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
    any(CommandInjectionAdditionalTaintStep s).step(pred, succ) or
    isProjectCommandInjectionFlowStep(pred, succ)
  }
}

module SpringCommandInjectionFlow = TaintTracking::Global<SpringCommandInjectionConfig>;

import SpringCommandInjectionFlow::PathGraph

from SpringCommandInjectionFlow::PathNode source, SpringCommandInjectionFlow::PathNode sink
where SpringCommandInjectionFlow::flowPath(source, sink)
select sink.getNode().asExpr(), source, sink,
  "Spring MVC input reaches OS command execution."