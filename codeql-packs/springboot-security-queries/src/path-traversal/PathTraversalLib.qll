import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController
import semmle.code.java.security.PathSanitizer
import common.CommonTaintSteps
import common.FileSystemSinks

predicate isOfficialSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
}

/** Extension point for project-specific path traversal sinks. */
predicate isProjectPathTraversalSink(DataFlow::Node sink) {
  isFileReadOrWriteDestinationSink(sink)
}

/**
 * Default-layer sanitizer:
 * only keep official, hard-semantic path sanitizers.
 */
predicate isProjectPathTraversalSanitizer(DataFlow::Node node) {
  node instanceof PathInjectionSanitizer
}

/** Extension point for project-specific extra taint steps. */
predicate isProjectPathTraversalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  isCommonStringAssemblyStep(pred, succ)
}