import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSources
import semmle.code.java.frameworks.spring.SpringController
import common.SpringBindingSources

predicate isSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
  or
  isSpringMvcBoundObjectSourceNode(src)
}

predicate isServletWebSourceNode(DataFlow::Node src) {
  src instanceof RemoteFlowSource
}

predicate isAnyWebInputSourceNode(DataFlow::Node src) {
  isSpringMvcSourceNode(src) or
  isServletWebSourceNode(src)
}