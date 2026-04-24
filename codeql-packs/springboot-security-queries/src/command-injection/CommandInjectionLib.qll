import java
import semmle.code.java.controlflow.Guards
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController
import semmle.code.java.security.CommandLineQuery
import common.CommonTaintSteps
import common.SpringBindingSources

predicate isOfficialSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
}

// 若e为编译期可确定的字符串常量表达式(e = "My"+"SQL"), 且e的值等于字符串s(s = "MySQL"), 则为真
private predicate hasStringValue(Expr e, string s) {
  exists(CompileTimeConstantExpr c |
    c = e and
    c.getStringValue() = s
  )
}

private predicate isUnixShellName(Expr e) {
  hasStringValue(e, "sh") or
  hasStringValue(e, "/bin/sh") or
  hasStringValue(e, "bash") or
  hasStringValue(e, "/bin/bash")
}

private predicate isWindowsShellName(Expr e) {
  hasStringValue(e, "cmd") or
  hasStringValue(e, "cmd.exe")
}

private predicate isPowerShellName(Expr e) {
  hasStringValue(e, "powershell") or
  hasStringValue(e, "powershell.exe") or
  hasStringValue(e, "pwsh") or
  hasStringValue(e, "pwsh.exe")
}

// 判断该命令是否为启动shell执行, 如cmd -c ping或者sh -c ping
private predicate isShellLauncher(Expr launcher, Expr flag) {
  isUnixShellName(launcher) and hasStringValue(flag, "-c")
  or
  isWindowsShellName(launcher) and hasStringValue(flag, "/c")
  or
  isPowerShellName(launcher) and
  (hasStringValue(flag, "-Command") or hasStringValue(flag, "-command"))
}

// call调用的是否是ProcessBuilder(cmd)或者ProcessBuilder.command(cmd)其中的一种, 且这些方法均只有一个参数
private predicate isProcessBuilderListCall(Call call) {
  exists(Constructor c |
    call.getCallee() = c and
    c.getDeclaringType().hasQualifiedName("java.lang", "ProcessBuilder") and
    c.getNumberOfParameters() = 1
  )
  or
  exists(Method m |
    call.getCallee() = m and
    m.getDeclaringType().hasQualifiedName("java.lang", "ProcessBuilder") and
    m.hasName("command") and
    m.getNumberOfParameters() = 1
  )
}

// expr为List.of("sh", "-c", cmd)或者Arrays.asList("cmd", "-c", cmd)多种组合
private predicate isShellLauncherListExpr(Expr expr) {
  exists(MethodCall mc |
    expr = mc and
    isCommonListFactoryExpr(mc) and
    isShellLauncher(mc.getArgument(0), mc.getArgument(1))
  )
}

/**
 * 只补一类官方 baseline 容易漏掉、但你文档里明确想区分的情况：
 * ProcessBuilder(List<String>) / pb.command(List<String>)
 * 且 list 形如 ["sh", "-c", tainted] / ["cmd.exe", "/c", tainted]
 */
private class ShellLauncherListSink extends CommandInjectionSink {
  ShellLauncherListSink() {
    exists(Call call, Expr argv |
      isProcessBuilderListCall(call) and // ProcessBuilder(cmd)或ProcessBuilder.command(cmd)
      argv = call.getArgument(0) and // argv = cmd
      isShellLauncherListExpr(argv) and // argv = cmd = List.of("sh", "-c", cmd)等
      this.asExpr() = argv // 最终匹配ProcessBuilder(List.of("sh", "-c", cmd))等
    )
  }
}

predicate isProjectCommandInjectionSink(DataFlow::Node sink) {
  sink instanceof ShellLauncherListSink
}

predicate isProjectCommandInjectionFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  isCommonStringAssemblyStep(pred, succ)
  or
  isCommonListFactoryFlowStep(pred, succ)
  or
  isSpringBoundObjectPropertyReadStep(pred, succ)
}

predicate isProjectCommandInjectionSanitizer(DataFlow::Node node) { none() }
