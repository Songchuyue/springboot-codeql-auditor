/**
 * @name SpringBoot path traversal (LLM candidate mode)
 * @description Spring MVC user input reaches a file-system access path. Project-specific sanitizer heuristics are intentionally disabled so an LLM can triage candidate paths afterwards.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision medium
 * @id scy/java/path-traversal-llm-candidate
 * @tags security
 *       external/cwe/cwe-022
 *       external/cwe/cwe-023
 *       external/cwe/cwe-036
 *       external/cwe/cwe-073
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.security.TaintedPathQuery
import semmle.code.java.security.PathSanitizer
import PathTraversalLib
import common.WebRequestSources

module SpringPathTraversalLlmCandidateConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) { isAnyWebInputSourceNode(src) }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof TaintedPathSink or
    isProjectPathTraversalSink(sink)
  }

  predicate isBarrier(DataFlow::Node node) {
    // Keep only official path sanitizers. Project-specific name/guard heuristics are
    // left to the post-LLM triage phase.
    node instanceof PathInjectionSanitizer
  }

  predicate isAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
    any(TaintedPathAdditionalTaintStep s).step(pred, succ) or
    isProjectPathTraversalFlowStep(pred, succ)
  }
}

module SpringPathTraversalLlmCandidateFlow = TaintTracking::Global<SpringPathTraversalLlmCandidateConfig>;
import SpringPathTraversalLlmCandidateFlow::PathGraph

from
  SpringPathTraversalLlmCandidateFlow::PathNode source,
  SpringPathTraversalLlmCandidateFlow::PathNode sink
where
  SpringPathTraversalLlmCandidateFlow::flowPath(source, sink)
select sink.getNode().asExpr(), source, sink,
  "Spring MVC input reaches a file-system access path (project-specific sanitizers deferred to LLM triage)."
