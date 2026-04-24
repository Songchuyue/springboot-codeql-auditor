/**
 * common/SpringAopModel.qll
 *
 * 最小 Spring AOP 语义层：
 * 1. @Aspect 类型
 * 2. @Before / @Around / @After / @AfterReturning 方法
 * 3. 直接字符串 execution(...) pointcut 的粗粒度匹配
 * 4. self-invocation
 * 5. private/static/final 代理不友好方法
 *
 * 说明：
 * - 这里只支持“直接写在 advice 注解里的字符串 pointcut”
 * - 暂不解析 @Pointcut 方法间接引用、复杂 pointcut 组合、XML AOP 配置
 */

import java

private predicate hasQualifiedAnnotation(Annotatable a, string pkg, string name) {
  exists(Annotation ann |
    ann = a.getAnAnnotation() and
    ann.getType().hasQualifiedName(pkg, name)
  )
}

/** -----------------------------
 *  Aspect / advice identification
 *  ----------------------------- */
predicate isSpringAspectType(RefType t) {
  hasQualifiedAnnotation(t, "org.aspectj.lang.annotation", "Aspect")
}

class SpringAspectType extends RefType {
  SpringAspectType() { isSpringAspectType(this) }
}

private predicate isAdviceAnnotation(Annotation ann, string kind) {
  kind = "Before" and ann.getType().hasQualifiedName("org.aspectj.lang.annotation", "Before")
  or
  kind = "Around" and ann.getType().hasQualifiedName("org.aspectj.lang.annotation", "Around")
  or
  kind = "After" and ann.getType().hasQualifiedName("org.aspectj.lang.annotation", "After")
  or
  kind = "AfterReturning" and ann.getType().hasQualifiedName("org.aspectj.lang.annotation", "AfterReturning")
}

private predicate isAnyAdviceAnnotation(Annotation ann) {
  exists(string kind | isAdviceAnnotation(ann, kind))
}

predicate isAdviceMethod(Method m) {
  isSpringAspectType(m.getDeclaringType()) and
  exists(Annotation ann |
    ann = m.getAnAnnotation() and
    isAnyAdviceAnnotation(ann)
  )
}

// 方法所在类带有@Aspect, 方法本身带有@Before, @After, @Around等
class SpringAdviceMethod extends Method {
  SpringAdviceMethod() { isAdviceMethod(this) }
}

predicate getAdviceKind(Method m, string kind) {
  exists(Annotation ann |
    ann = m.getAnAnnotation() and
    isAdviceAnnotation(ann, kind)
  )
}

/**
 * 取 advice 注解上的 pointcut 字符串：
 * - @Before("execution(...)")
 * - @AfterReturning(pointcut="execution(...)", returning="ret")
 */
predicate getAdvicePointcut(Method m, string pointcut) {
  exists(Annotation ann |
    ann = m.getAnAnnotation() and
    isAnyAdviceAnnotation(ann) and
    (
      pointcut = ann.getStringValue("value")
      or
      pointcut = ann.getStringValue("pointcut")
    ) and
    pointcut != ""
  )
}

/** -----------------------------
 *  Optional: @Pointcut method
 *  ----------------------------- */
predicate isPointcutMethod(Method m) {
  isSpringAspectType(m.getDeclaringType()) and
  hasQualifiedAnnotation(m, "org.aspectj.lang.annotation", "Pointcut")
}

predicate getPointcutExpression(Method m, string pointcut) {
  exists(Annotation ann |
    ann = m.getAnAnnotation() and
    ann.getType().hasQualifiedName("org.aspectj.lang.annotation", "Pointcut") and
    (
      pointcut = ann.getStringValue("value")
      or
      pointcut = ann.getStringValue("pointcut")
    ) and
    pointcut != ""
  )
}

/**
 * -----------------------------
 * Resolved advice pointcut
 * -----------------------------
 *
 * 支持：
 *   @Before("execution(...)")
 *   @Before("controllerPointcut()")
 *   @Before("controllerPointcut() && args(id)")
 *
 * 仍然不支持：
 *   XML AOP
 *   完整 AspectJ 语法解析
 *   任意复杂布尔表达式精确求值
 */
bindingset[advice, raw]
private predicate pointcutMethodReferenceMayResolveTo(Method advice, string raw, Method pcMethod) {
  isPointcutMethod(pcMethod) and
  pcMethod.getDeclaringType() = advice.getDeclaringType() and
  (
    raw = pcMethod.getName() + "()" or
    raw.matches("%" + pcMethod.getName() + "()%") or
    raw.matches("%this." + pcMethod.getName() + "()%") or
    raw.matches("%" + pcMethod.getDeclaringType().getName() + "." + pcMethod.getName() + "()%") or
    raw.matches("%" + pcMethod.getDeclaringType().getQualifiedName() + "." + pcMethod.getName() + "()%")
  )
}

bindingset[advice, raw]
private predicate adviceLiteralHasPointcutMethodReference(Method advice, string raw) {
  exists(Method pcMethod |
    pointcutMethodReferenceMayResolveTo(advice, raw, pcMethod)
  )
}

/**
 * advice 的有效 pointcut：
 * 1. 如果 advice 里直接写 execution/within/args/@annotation，就直接使用；
 * 2. 如果 advice 里引用 @Pointcut 方法，则展开该 @Pointcut 方法上的表达式。
 */
predicate getResolvedAdvicePointcut(Method advice, string pc) {
  getAdvicePointcut(advice, pc) and
  not adviceLiteralHasPointcutMethodReference(advice, pc)
  or
  exists(string raw, Method pcMethod |
    getAdvicePointcut(advice, raw) and
    pointcutMethodReferenceMayResolveTo(advice, raw, pcMethod) and
    getPointcutExpression(pcMethod, pc)
  )
}

/**
 * 如果 raw advice pointcut 中还带了 args(...) 这类内联约束，
 * 这里只做低成本近似：有 args(...) 时，要求目标方法至少有参数。
 *
 * 例如：
 *   @Before("controllerPointcut() && args(id)")
 */
bindingset[raw, target]
private predicate inlineArgsConstraintMayHold(string raw, Method target) {
  not raw.matches("%args(%")
  or
  raw.matches("%args()%") and target.getNumberOfParameters() = 0
  or
  raw.matches("%args(%") and target.getNumberOfParameters() > 0
}

bindingset[raw, target]
private predicate inlineAnnotationConstraintMayHold(string raw, Method target) {
  not raw.matches("%@annotation(%")
  or
  exists(Annotation ann |
    ann = target.getAnAnnotation() and
    (
      raw.matches("%@annotation(" + ann.getType().getQualifiedName() + ")%") or
      raw.matches("%@annotation(" + ann.getType().getName() + ")%")
    )
  )
}

/**
 * execution(...)
 *
 * 支持常见形式：
 *   execution(* com.foo.UserService.save(..))
 *   execution(* UserService.save(..))
 *   execution(* *.save(..))
 *   execution(* com.foo..*.save(..))   // 粗略包名前缀
 */
bindingset[pc, target]
private predicate executionPointcutMayMatchTarget(string pc, Method target) {
  pc.matches("%execution(%") and
  (
    pc.matches("%" + target.getDeclaringType().getQualifiedName() + "." + target.getName() + "(..)%") or
    pc.matches("%" + target.getDeclaringType().getQualifiedName() + "." + target.getName() + "()%") or
    pc.matches("%" + target.getDeclaringType().getName() + "." + target.getName() + "(..)%") or
    pc.matches("%" + target.getDeclaringType().getName() + "." + target.getName() + "()%") or
    pc.matches("%*." + target.getName() + "(..)%") or
    pc.matches("%*." + target.getName() + "()%") or
    pc.matches("%" + target.getDeclaringType().getPackage().getName() + "..*." + target.getName() + "(..)%")
  )
}

/**
 * within(...)
 *
 * 支持常见形式：
 *   within(com.foo..*)
 *   within(com.foo.UserService)
 *   within(UserService)
 */
bindingset[pc, target]
private predicate withinPointcutMayMatchTarget(string pc, Method target) {
  pc.matches("%within(%") and
  (
    pc.matches("%within(" + target.getDeclaringType().getQualifiedName() + ")%") or
    pc.matches("%within(" + target.getDeclaringType().getName() + ")%") or
    pc.matches("%within(" + target.getDeclaringType().getPackage().getName() + "..*)%") or
    pc.matches("%within(" + target.getDeclaringType().getPackage().getName() + ".*)%")
  )
}

/**
 * @annotation(...)
 *
 * 支持：
 *   @annotation(com.foo.RequiresPermission)
 *   @annotation(RequiresPermission)
 */
bindingset[pc, target]
private predicate annotationPointcutMayMatchTarget(string pc, Method target) {
  pc.matches("%@annotation(%") and
  exists(Annotation ann |
    ann = target.getAnAnnotation() and
    (
      pc.matches("%@annotation(" + ann.getType().getQualifiedName() + ")%") or
      pc.matches("%@annotation(" + ann.getType().getName() + ")%")
    )
  )
}

/**
 * args(...)
 *
 * 只做粗粒度匹配：
 * - args()       -> 0 参数
 * - args(..)     -> 任意参数
 * - args(id)     -> 至少一个参数，id 视为变量名，不做类型判断
 * - args(com.foo.X) / args(X) -> 至少有一个参数类型匹配
 */
bindingset[pc, target]
private predicate argsPointcutMayMatchTarget(string pc, Method target) {
  pc.matches("%args(..)%")
  or
  pc.matches("%args()%") and target.getNumberOfParameters() = 0
  or
  pc.matches("%args(%") and target.getNumberOfParameters() > 0
  or
  exists(int i, RefType pt |
    i >= 0 and i < target.getNumberOfParameters() and
    pt = target.getParameter(i).getType() and
    (
      pc.matches("%args(" + pt.getQualifiedName() + ")%") or
      pc.matches("%args(" + pt.getName() + ")%") or
      pc.matches("%, " + pt.getQualifiedName() + ",%") or
      pc.matches("%, " + pt.getName() + ",%")
    )
  )
}

bindingset[pc, target]
private predicate pointcutMayMatchTarget(string pc, Method target) {
  executionPointcutMayMatchTarget(pc, target)
  or withinPointcutMayMatchTarget(pc, target)
  or annotationPointcutMayMatchTarget(pc, target)
  or argsPointcutMayMatchTarget(pc, target)
}

/** -----------------------------
 *  JoinPoint helpers
 *  ----------------------------- */
predicate isJoinPointType(RefType t) {
  exists(RefType a |
    a = t.getAnAncestor() and
    (
      a.hasQualifiedName("org.aspectj.lang", "JoinPoint")
      or
      a.hasQualifiedName("org.aspectj.lang", "ProceedingJoinPoint")
    )
  )
}

predicate isJoinPointParameter(Parameter p) {
  exists(RefType t |
    t = p.getType() and
    isJoinPointType(t)
  )
}

predicate isJoinPointGetArgsCall(MethodCall mc) {
  mc.getMethod().hasName("getArgs") and
  exists(RefType a |
    a = mc.getReceiverType().getAnAncestor() and
    (
      a.hasQualifiedName("org.aspectj.lang", "JoinPoint")
      or
      a.hasQualifiedName("org.aspectj.lang", "ProceedingJoinPoint")
    )
  )
}

/**
 * pointcut 文本层面可能匹配目标方法。
 *
 * 注意：
 * - 这个谓词只表示 pointcut 模式可能匹配；
 * - 不代表 Spring 代理一定能拦截；
 * - 是否能被代理拦截请用 adviceMayActuallyInterceptMethod。
 */
predicate adviceMayMatchMethod(Method advice, Method target) {
  isAdviceMethod(advice) and
  target.fromSource() and
  (
    exists(string pc |
      getResolvedAdvicePointcut(advice, pc) and
      pointcutMayMatchTarget(pc, target)
    )
    or
    exists(string raw, Method pcMethod, string pc |
      getAdvicePointcut(advice, raw) and
      pointcutMethodReferenceMayResolveTo(advice, raw, pcMethod) and
      getPointcutExpression(pcMethod, pc) and
      pointcutMayMatchTarget(pc, target) and
      inlineArgsConstraintMayHold(raw, target) and
      inlineAnnotationConstraintMayHold(raw, target)
    )
  )
}

/** -----------------------------
 *  Self-invocation
 *  ----------------------------- */
predicate isSelfInvocationCall(Method caller, MethodCall call, Method callee) {
  caller = call.getEnclosingCallable() and
  callee = call.getMethod() and
  call.isOwnMethodCall()
}

predicate isSelfInvocation(MethodCall call) {
  exists(Method caller, Method callee |
    isSelfInvocationCall(caller, call, callee)
  )
}

predicate isAdvisedSelfInvocation(Method caller, MethodCall call, Method callee, Method advice) {
  isSelfInvocationCall(caller, call, callee) and
  adviceMayMatchMethod(advice, callee)
}

/** -----------------------------
 *  Proxy-unfriendly target methods
 *  ----------------------------- */
predicate isProxyUnsafeTargetMethod(Method m) {
  m.isPrivate() or
  m.isStatic() or
  m.isFinal()
}

/**
 * Spring proxy-based AOP 实际可能拦截。
 *
 * private/static/final 方法不作为“可拦截目标”处理。
 */
predicate adviceMayActuallyInterceptMethod(Method advice, Method target) {
  adviceMayMatchMethod(advice, target) and
  not isProxyUnsafeTargetMethod(target)
}

/**
 * -----------------------------
 * @Around proceed() ordering
 * -----------------------------
 */

predicate isProceedCall(MethodCall mc) {
  mc.getMethod().hasName("proceed") and
  exists(RefType a |
    a = mc.getReceiverType().getAnAncestor() and
    a.hasQualifiedName("org.aspectj.lang", "ProceedingJoinPoint")
  )
}

predicate aroundAdviceCallsProceed(Method advice) {
  getAdviceKind(advice, "Around") and
  exists(MethodCall proceed |
    proceed.getEnclosingCallable() = advice and
    isProceedCall(proceed)
  )
}

/**
 * call 位于 proceed() 之前。
 *
 * 这是源码行号近似，不是严格 CFG 支配关系。
 */
predicate callIsBeforeProceedInAroundAdvice(Method advice, MethodCall call) {
  getAdviceKind(advice, "Around") and
  call.getEnclosingCallable() = advice and
  exists(MethodCall proceed |
    proceed.getEnclosingCallable() = advice and
    isProceedCall(proceed) and
    call != proceed and
    call.getLocation().getFile() = proceed.getLocation().getFile() and
    call.getLocation().getStartLine() <= proceed.getLocation().getStartLine()
  )
}

/**
 * call 位于 proceed() 之后。
 */
predicate callIsAfterProceedInAroundAdvice(Method advice, MethodCall call) {
  getAdviceKind(advice, "Around") and
  call.getEnclosingCallable() = advice and
  exists(MethodCall proceed |
    proceed.getEnclosingCallable() = advice and
    isProceedCall(proceed) and
    call != proceed and
    call.getLocation().getFile() = proceed.getLocation().getFile() and
    call.getLocation().getStartLine() >= proceed.getLocation().getStartLine()
  )
}