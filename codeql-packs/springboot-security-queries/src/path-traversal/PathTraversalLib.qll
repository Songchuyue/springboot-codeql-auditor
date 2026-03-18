import java

import semmle.code.java.controlflow.Guards
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController
import semmle.code.java.security.PathSanitizer

predicate isOfficialSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
}

/**
 * Guard-style sanitizer extension point.
 *
 * Typical examples:
 *   if (!PathUtil.isSafeRelativePath(name)) return ...;
 *   if (!FileNamePolicy.isSafeFilename(name)) throw ...;
 */
private predicate safeRelativePathGuard(Guard g, Expr e, boolean branch) {
  exists(MethodCall mc |
    mc.getMethod().getNumberOfParameters() = 1 and
    (
      mc.getMethod().hasName("isSafeRelativePath") or
      mc.getMethod().hasName("isSafeFilename") or
      mc.getMethod().hasName("isSafePathSegment")
    ) and
    g = mc and
    e = mc.getArgument(0) and
    branch = true
  )
}

/** Extension point for project-specific path traversal sinks. */
predicate isProjectPathTraversalSink(DataFlow::Node sink) { none() }

/**
 * Extension point for built-in and project-specific sanitizers.
 *
 * 1) Reuse official path-injection sanitizers.
 * 2) Recognize a few project-friendly return-value sanitizers by name.
 * 3) Recognize guard-style validators.
 */
predicate isProjectPathTraversalSanitizer(DataFlow::Node node) {
  node instanceof PathInjectionSanitizer
  or
  exists(MethodCall mc |
    mc.getMethod().getNumberOfParameters() = 1 and
    (
      mc.getMethod().hasName("sanitizeFilename") or
      mc.getMethod().hasName("toSafeFilename") or
      mc.getMethod().hasName("sanitizePathSegment")
    ) and
    node = DataFlow::exprNode(mc)
  )
  or
  node = DataFlow::BarrierGuard<safeRelativePathGuard/3>::getABarrierNode()
}

/** Extension point for project-specific extra taint steps. */
predicate isProjectPathTraversalFlowStep(DataFlow::Node pred, DataFlow::Node succ) { none() }