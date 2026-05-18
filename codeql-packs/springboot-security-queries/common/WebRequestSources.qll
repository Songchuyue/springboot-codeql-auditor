import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSources
import semmle.code.java.frameworks.spring.SpringController
import common.SpringBindingSources

/**
 * isSpringMvcSourceNode
 * ├─ 第一部分：普通 Spring MVC 入参
 * │  例如 @RequestParam String name
 * │       @PathVariable String id
 * │
 * └─ 第二部分：Spring MVC 绑定对象
 *    例如 @RequestBody UserDTO dto
 *         @ModelAttribute UserQuery query
 *         @Valid UserDTO dto
 *         未显式注解但像 DTO 的复杂对象参数
 */
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