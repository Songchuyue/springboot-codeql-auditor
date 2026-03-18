import java

import semmle.code.java.controlflow.Guards
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController
import semmle.code.java.security.LogInjection

predicate isOfficialSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
}

private predicate isProjectLoggerLikeType(RefType t) {
  not t.hasQualifiedName("org.slf4j", "Logger") and
  (
    t.getName().matches("%Logger%") or
    t.getName().matches("%LogUtil%") or
    t.getName().matches("%LoggingService%")
  )
}

private predicate isProjectLoggingMethod(Method m) {
  exists(RefType t |
    t = m.getDeclaringType() and
    isProjectLoggerLikeType(t)
  ) and
  (
    m.hasName("trace") or
    m.hasName("debug") or
    m.hasName("info") or
    m.hasName("warn") or
    m.hasName("error") or
    m.hasName("log")
  )
}

private class ProjectLoggerSink extends LogInjectionSink {
  ProjectLoggerSink() {
    exists(MethodCall mc, Expr arg |
      isProjectLoggingMethod(mc.getMethod()) and
      arg = mc.getAnArgument() and
      this.asExpr() = arg
    )
  }
}

predicate isProjectLogInjectionSink(DataFlow::Node sink) {
  sink instanceof ProjectLoggerSink
}

private predicate logSafeGuard(Guard g, Expr e, boolean branch) {
  exists(MethodCall mc |
    mc.getMethod().getNumberOfParameters() = 1 and
    (
      mc.getMethod().hasName("isSafeForLog") or
      mc.getMethod().hasName("hasNoLineBreaks") or
      mc.getMethod().hasName("containsNoLineBreaks")
    ) and
    g = mc and
    e = mc.getArgument(0) and
    branch = true
  )
}

predicate isProjectLogInjectionSanitizer(DataFlow::Node node) {
  exists(MethodCall mc |
    mc.getMethod().getNumberOfParameters() = 1 and
    (
      mc.getMethod().hasName("sanitizeForLog") or
      mc.getMethod().hasName("stripCrLf") or
      mc.getMethod().hasName("removeLineBreaks") or
      mc.getMethod().hasName("normalizeForLog")
    ) and
    node = DataFlow::exprNode(mc)
  )
  or
  node = DataFlow::BarrierGuard<logSafeGuard/3>::getABarrierNode()
}

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

predicate isProjectLogInjectionFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
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
  or
  exists(MethodCall mc |
    isBuilderToStringMethod(mc.getMethod()) and
    pred = DataFlow::exprNode(mc.getQualifier()) and
    succ = DataFlow::exprNode(mc)
  )
  or
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