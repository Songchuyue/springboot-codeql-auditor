import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.security.LogInjection

private predicate isProjectLoggerLikeType(RefType t) {
  not t.hasQualifiedName("org.slf4j", "Logger") and
  not t.hasQualifiedName("java.util.logging", "Logger") and
  (
    t.getName().matches("%Logger%") or
    t.getName().matches("%LogUtil%") or
    t.getName().matches("%LoggingService%")
  )
}

predicate isProjectLoggingMethod(Method m) {
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

private predicate isProjectLogMessageArgument(MethodCall mc, Expr arg) {
  isProjectLoggingMethod(mc.getMethod()) and
  (
    arg = mc.getArgument(0)
    or
    exists(StringLiteral fmt |
      fmt = mc.getArgument(0) and
      arg = mc.getAnArgument() and
      arg != fmt
    )
  )
}

class ProjectLoggerSink extends LogInjectionSink {
  ProjectLoggerSink() {
    exists(MethodCall mc, Expr arg |
      isProjectLogMessageArgument(mc, arg) and
      this.asExpr() = arg
    )
  }
}

predicate isProjectLogInjectionSink(DataFlow::Node sink) {
  sink instanceof ProjectLoggerSink
}