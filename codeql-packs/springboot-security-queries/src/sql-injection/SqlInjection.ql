/**
 * @name SpringBoot SQL injection
 * @description Spring MVC user input reaches dynamic SQL or JPQL query text.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 8.8
 * @precision high
 * @id scy/java/sql-injection
 * @tags security
 *       external/cwe/cwe-089
 *       external/cwe/cwe-564
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.security.QueryInjection
import semmle.code.java.security.Sanitizers
import SqlInjectionLib
import WebRequestSources

module SpringSqlInjectionConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    isAnyWebInputSourceNode(src)
  }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof QueryInjectionSink
  }

  predicate isBarrier(DataFlow::Node node) {
    node instanceof SimpleTypeSanitizer or
    isProjectSqlSanitizer(node)
  }

  predicate isAdditionalFlowStep(DataFlow::Node node1, DataFlow::Node node2) {
    any(AdditionalQueryInjectionTaintStep s).step(node1, node2) or
    isProjectSqlFlowStep(node1, node2)
  }
}

module SpringSqlInjectionFlow = TaintTracking::Global<SpringSqlInjectionConfig>;
import SpringSqlInjectionFlow::PathGraph

from SpringSqlInjectionFlow::PathNode source, SpringSqlInjectionFlow::PathNode sink
where
  SpringSqlInjectionFlow::flowPath(source, sink)
select sink.getNode().asExpr(), source, sink,
  "Spring MVC input reaches dynamic SQL/JPQL query text."