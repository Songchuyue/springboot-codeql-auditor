import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController
import common.CommonTaintSteps
import common.SpringBindingSources

predicate isOfficialSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
}

/** Extension point for project-specific sanitizers. */
predicate isProjectSqlSanitizer(DataFlow::Node node) {
  none()
}

/** Extension point for project-specific extra taint steps. */
predicate isProjectSqlFlowStep(DataFlow::Node n1, DataFlow::Node n2) {
  isCommonStringAssemblyStep(n1, n2)
  or
  isSpringBoundObjectPropertyReadStep(n1, n2)
}