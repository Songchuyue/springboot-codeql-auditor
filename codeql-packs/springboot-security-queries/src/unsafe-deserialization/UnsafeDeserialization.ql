/**
 * @name SpringBoot unsafe deserialization
 * @description Spring MVC user input reaches unsafe object deserialization.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.8
 * @precision high
 * @id scy/java/unsafe-deserialization
 * @tags security
 *       external/cwe/cwe-502
 */

import java
import semmle.code.java.security.UnsafeDeserializationQuery
import UnsafeDeserializationLib
import WebRequestSources

import UnsafeDeserializationFlow::PathGraph

from UnsafeDeserializationFlow::PathNode source, UnsafeDeserializationFlow::PathNode sink
where
  UnsafeDeserializationFlow::flowPath(source, sink) and
  isAnyWebInputSourceNode(source.getNode())
select
  sink.getNode().(UnsafeDeserializationSink).getMethodCall(),
  source,
  sink,
  "Spring MVC input reaches unsafe deserialization."