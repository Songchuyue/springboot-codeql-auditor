import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.security.LogInjection
import common.SpringBeanModel

private predicate isProjectLoggerLikeType(RefType t) {
  not t.hasQualifiedName("org.slf4j", "Logger") and
  not t.hasQualifiedName("java.util.logging", "Logger") and
  (
    t.getName().matches("%Logger%") or
    t.getName().matches("%LogUtil%") or
    t.getName().matches("%LoggingService%") or
    t.getName().matches("%Audit%") or
    t.getName().matches("%AuditService%") or
    t.getName().matches("%AuditLog%") or
    t.getName().matches("%OperationLog%") or
    t.getName().matches("%LogService%")
  )
}

private predicate isProjectLoggingMethodName(string name) {
  name = "trace" or
  name = "debug" or
  name = "info" or
  name = "warn" or
  name = "error" or
  name = "log" or
  name = "record" or
  name = "audit" or
  name = "saveLog"
}

predicate isProjectLoggingMethod(Method m) {
  exists(RefType t |
    t = m.getDeclaringType() and
    isProjectLoggerLikeType(t)
  ) and
  isProjectLoggingMethodName(m.getName())
}

/**
 * 新增：调用点接 DI
 * 例如 auditService.record(...), operationLogService.saveLog(...)
 */
private predicate isInjectedProjectLoggingCall(MethodCall mc) {
  isProjectLoggingMethodName(mc.getMethod().getName()) and
  exists(RefType impl |
    injectedFieldReceiverCallMayResolveToBeanType(mc, impl) and
    isProjectLoggerLikeType(impl)
  )
}

private predicate isProjectLogMessageArgument(MethodCall mc, Expr arg) {
  (isProjectLoggingMethod(mc.getMethod()) or isInjectedProjectLoggingCall(mc)) and
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