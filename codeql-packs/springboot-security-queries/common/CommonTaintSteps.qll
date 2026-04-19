import java
import semmle.code.java.dataflow.DataFlow

private predicate isBuilderType(RefType t) {
  t.hasQualifiedName("java.lang", "StringBuilder") or
  t.hasQualifiedName("java.lang", "StringBuffer")
}

private predicate isBuilderAppendMethod(Method m) {
  m.hasName("append") and
  exists(RefType t |
    t = m.getDeclaringType() and
    isBuilderType(t)
  )
}

private predicate isBuilderToStringMethod(Method m) {
  m.hasName("toString") and
  exists(RefType t |
    t = m.getDeclaringType() and
    isBuilderType(t)
  )
}

private predicate isStringFormatMethod(Method m) {
  m.hasQualifiedName("java.lang", "String", "format")
}

private predicate isStringConcatMethod(Method m) {
  m.hasQualifiedName("java.lang", "String", "concat")
}

private predicate isListFactoryCall(MethodCall mc) {
  mc.getMethod().hasQualifiedName("java.util", "Arrays", "asList") or
  mc.getMethod().hasQualifiedName("java.util", "List", "of")
}

predicate isCommonListFactoryExpr(Expr e) {
  exists(MethodCall mc |
    e = mc and
    isListFactoryCall(mc)
  )
}

predicate isCommonBuilderAppendFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  exists(MethodCall mc, DataFlow::PostUpdateNode post |
    isBuilderAppendMethod(mc.getMethod()) and
    pred = DataFlow::exprNode(mc.getArgument(0)) and
    post.getPreUpdateNode() = DataFlow::exprNode(mc.getQualifier()) and
    succ = post
  )
  or
  exists(MethodCall mc, DataFlow::PostUpdateNode post |
    isBuilderAppendMethod(mc.getMethod()) and
    pred = post.getPreUpdateNode() and
    post.getPreUpdateNode() = DataFlow::exprNode(mc.getQualifier()) and
    succ = post
  )
}

predicate isCommonBuilderToStringFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  exists(MethodCall mc |
    isBuilderToStringMethod(mc.getMethod()) and
    pred = DataFlow::exprNode(mc.getQualifier()) and
    succ = DataFlow::exprNode(mc)
  )
}

predicate isCommonStringFormatFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  exists(MethodCall mc, int i |
    isStringFormatMethod(mc.getMethod()) and
    succ = DataFlow::exprNode(mc) and
    (
      (
        mc.getMethod().getNumberOfParameters() = 2 and
        i >= 1 and
        pred = DataFlow::exprNode(mc.getArgument(i))
      )
      or
      (
        mc.getMethod().getNumberOfParameters() = 3 and
        i >= 2 and
        pred = DataFlow::exprNode(mc.getArgument(i))
      )
    )
  )
}

predicate isCommonStringConcatFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  exists(MethodCall mc |
    isStringConcatMethod(mc.getMethod()) and
    succ = DataFlow::exprNode(mc) and
    (
      pred = DataFlow::exprNode(mc.getQualifier())
      or
      pred = DataFlow::exprNode(mc.getArgument(0))
    )
  )
}

predicate isCommonListFactoryFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  exists(MethodCall mc, int i |
    isListFactoryCall(mc) and
    i >= 0 and
    pred = DataFlow::exprNode(mc.getArgument(i)) and
    succ = DataFlow::exprNode(mc)
  )
}

predicate isCommonStringAssemblyStep(DataFlow::Node pred, DataFlow::Node succ) {
  isCommonBuilderAppendFlowStep(pred, succ) or
  isCommonBuilderToStringFlowStep(pred, succ) or
  isCommonStringFormatFlowStep(pred, succ) or
  isCommonStringConcatFlowStep(pred, succ)
}