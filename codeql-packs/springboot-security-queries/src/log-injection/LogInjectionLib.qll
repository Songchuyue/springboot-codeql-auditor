import java

import semmle.code.java.controlflow.Guards
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController
import semmle.code.java.security.LogInjection
import common.SpringAopModel

predicate isOfficialSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
}


// 判定该类的类型名中是否包括Logger, LogUtil, LoggingService, 但不包括org.slf4j.Logger
private predicate isProjectLoggerLikeType(RefType t) {
  not t.hasQualifiedName("org.slf4j", "Logger") and
  (
    t.getName().matches("%Logger%") or
    t.getName().matches("%LogUtil%") or
    t.getName().matches("%LoggingService%")
  )
}

// 判定该方法属于Logger, LogUtil, LoggingService, 且名为trace, debug, info, warn, error, log
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

// 识别 slf4j Logger 的常见日志方法
private predicate isSlf4jLoggingMethod(Method m) {
  m.getDeclaringType().hasQualifiedName("org.slf4j", "Logger") and
  (
    m.hasName("trace") or
    m.hasName("debug") or
    m.hasName("info") or
    m.hasName("warn") or
    m.hasName("error")
  )
}

// “任何日志方法” = slf4j 官方 logger + 你项目里的 wrapper logger
private predicate isAnyLoggingMethod(Method m) {
  isSlf4jLoggingMethod(m) or
  isProjectLoggingMethod(m)
}

private predicate adviceLoggedExpr(Method advice, Expr logged) {
  exists(MethodCall mc |
    mc.getEnclosingCallable() = advice and
    isAnyLoggingMethod(mc.getMethod()) and
    logged = mc.getAnArgument()
  )
}

/**
 * advice 中某个“非 JoinPoint 参数”是否流入了日志表达式
 * 这里只做结构包含判断，不做 pointcut args(...) 的精确位置绑定
 */
private predicate adviceParameterFlowsToLoggedExpr(Method advice, Parameter p) {
  exists(Expr logged, VarAccess acc |
    adviceLoggedExpr(advice, logged) and
    p.getCallable() = advice and
    not isJoinPointParameter(p) and
    acc = p.getAnAccess() and
    logged.getAChildExpr*() = acc
  )
}

/**
 * advice 中是否把 JoinPoint.getArgs() 直接放进日志表达式
 */
private predicate adviceJoinPointGetArgsFlowsToLoggedExpr(Method advice, MethodCall getArgsCall) {
  exists(Expr logged |
    adviceLoggedExpr(advice, logged) and
    getArgsCall.getEnclosingCallable() = advice and
    isJoinPointGetArgsCall(getArgsCall) and
    logged.getAChildExpr*() = getArgsCall
  )
}

// 将上一个谓词的方法的变量转为sink node
private class ProjectLoggerSink extends LogInjectionSink {
  ProjectLoggerSink() {
    exists(MethodCall mc, Expr arg |
      isProjectLoggingMethod(mc.getMethod()) and
      arg = mc.getAnArgument() and
      this.asExpr() = arg
    )
  }
}

// 同上
predicate isProjectLogInjectionSink(DataFlow::Node sink) {
  sink instanceof ProjectLoggerSink
}

predicate isProjectLogInjectionSanitizer(DataFlow::Node node) { none() }

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
  or
  // 目标方法调用实参 -> advice 的普通参数
  exists(MethodCall targetCall, Method advice, Method target, Parameter p, Expr arg |
    target = targetCall.getMethod() and
    adviceMayMatchMethod(advice, target) and
    adviceParameterFlowsToLoggedExpr(advice, p) and
    arg = targetCall.getAnArgument() and
    pred = DataFlow::exprNode(arg) and
    succ = DataFlow::parameterNode(p)
  )
  or
  // 目标方法调用实参 -> advice 中的 JoinPoint.getArgs()
  exists(MethodCall targetCall, Method advice, Method target, MethodCall getArgsCall, Expr arg |
    target = targetCall.getMethod() and
    adviceMayMatchMethod(advice, target) and
    adviceJoinPointGetArgsFlowsToLoggedExpr(advice, getArgsCall) and
    arg = targetCall.getAnArgument() and
    pred = DataFlow::exprNode(arg) and
    succ = DataFlow::exprNode(getArgsCall)
  )
}