/**
 * @name MyBatis XML ${} SQL injection in SpringBoot projects
 * @description User-controlled web input reaches a MyBatis mapper argument that is interpolated with `${...}` in mapper XML.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 8.8
 * @precision medium
 * @id scy/java/mybatis-xml-sql-injection
 * @tags security
 *       external/cwe/cwe-089
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.frameworks.MyBatis
import semmle.code.java.security.QueryInjection
import semmle.code.java.security.Sanitizers
import SqlInjectionLib
import common.WebRequestSources

private predicate myBatisParamName(Parameter p, string name) {
  name = p.getName()
  or
  exists(Annotation a |
    a = p.getAnAnnotation() and
    a.getType().hasQualifiedName("org.apache.ibatis.annotations", "Param") and
    name = a.getValue("value").(StringLiteral).getValue()
  )
}

bindingset[sql, name]
private predicate sqlTextHasUnsafeDollarPlaceholderForName(string sql, string name) {
  exists(string matched, int idx, int offset |
    matched = sql.regexpFind("\\$\\{" + name + "(\\.[^}]*)?\\}", idx, offset)
  )
}

bindingset[name]
private predicate mapperXmlUsesUnsafeDollarPlaceholderForName(MyBatisMapperSqlOperation op, string name) {
  exists(string sql |
    sql = op.getValue() and
    sqlTextHasUnsafeDollarPlaceholderForName(sql, name)
  )
  or
  exists(MyBatisMapperInclude inc, MyBatisMapperSql frag |
    inc = op.getInclude() and
    frag.getParent().(MyBatisMapperXmlElement).getNamespaceRefType() =
      op.getParent().(MyBatisMapperXmlElement).getNamespaceRefType() and
    frag.getId() = inc.getRefid() and
    sqlTextHasUnsafeDollarPlaceholderForName(frag.getValue(), name)
  )
}

private class MyBatisXmlDollarPlaceholderSink extends DataFlow::Node {
  MyBatisXmlDollarPlaceholderSink() {
    exists(MethodCall mc, Method mapperMethod, MyBatisMapperSqlOperation op,
      int i, Parameter p, string name |
      mc.getMethod() = mapperMethod and
      mapperMethod = op.getMapperMethod() and
      p = mapperMethod.getParameter(i) and
      myBatisParamName(p, name) and
      mapperXmlUsesUnsafeDollarPlaceholderForName(op, name) and
      this.asExpr() = mc.getArgument(i)
    )
  }
}

module MyBatisXmlDollarPlaceholderConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    isAnyWebInputSourceNode(src)
  }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof MyBatisXmlDollarPlaceholderSink
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

module MyBatisXmlDollarPlaceholderFlow =
  TaintTracking::Global<MyBatisXmlDollarPlaceholderConfig>;
import MyBatisXmlDollarPlaceholderFlow::PathGraph

from MyBatisXmlDollarPlaceholderFlow::PathNode source,
  MyBatisXmlDollarPlaceholderFlow::PathNode sink
where
  MyBatisXmlDollarPlaceholderFlow::flowPath(source, sink)
select sink.getNode().asExpr(), source, sink,
  "User-controlled data reaches a MyBatis mapper argument interpolated with `${...}` in mapper XML."
