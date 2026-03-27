/**
 * @name SpringBoot cross-site scripting (LLM candidate mode)
 * @description Spring MVC user input reaches an HTML response sink. Project-specific sanitizer heuristics are intentionally disabled so an LLM can triage candidate paths afterwards.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision medium
 * @id scy/java/xss-llm-candidate
 * @tags security
 *       external/cwe/cwe-079
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.security.Sanitizers
import semmle.code.java.security.XSS
import XssLib
import common.WebRequestSources

module SpringXssLlmCandidateConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) { isAnyWebInputSourceNode(src) }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof XssSink or
    isProjectXssSink(sink)
  }

  predicate isBarrier(DataFlow::Node node) {
    // Keep official generic/XSS sanitizers only. Project-level escape helpers are
    // reviewed later by the LLM from path context.
    node instanceof SimpleTypeSanitizer or
    node instanceof XssSanitizer
  }

  predicate isAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
    any(XssAdditionalTaintStep s).step(pred, succ) or
    isProjectXssFlowStep(pred, succ)
  }
}

module SpringXssLlmCandidateFlow = TaintTracking::Global<SpringXssLlmCandidateConfig>;
import SpringXssLlmCandidateFlow::PathGraph

from
  SpringXssLlmCandidateFlow::PathNode source,
  SpringXssLlmCandidateFlow::PathNode sink
where
  SpringXssLlmCandidateFlow::flowPath(source, sink)
select sink.getNode().asExpr(), source, sink,
  "Spring MVC input reaches an HTML response sink (project-specific sanitizers deferred to LLM triage)."
