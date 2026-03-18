import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController

/**
 * 只保留 Spring MVC 控制器入参作为 source。
 *
 * 反序列化的 sink / 额外传播 / 安全流判断，
 * 统一复用官方 UnsafeDeserializationFlow。
 */
predicate isOfficialSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
}