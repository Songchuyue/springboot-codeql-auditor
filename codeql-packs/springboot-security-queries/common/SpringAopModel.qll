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

/** -----------------------------
 *  Coarse pointcut -> target matching
 *  -----------------------------
 * 这里只做最小 execution(...) 匹配：
 * - execution(* com.foo.UserService.save(..))
 * - execution(* UserService.save(..))
 * - execution(* *.save(..))
 *
 * 不做精确参数签名解析，不解析 @Pointcut 间接引用。
 */
predicate adviceMayMatchMethod(Method advice, Method target) {
  isAdviceMethod(advice) and
  exists(string pc |
    getAdvicePointcut(advice, pc) and
    pc.matches("%execution(%") and
    (
      pc.matches("%" + target.getDeclaringType().getQualifiedName() + "." + target.getName() + "(..)%")
      or
      pc.matches("%" + target.getDeclaringType().getQualifiedName() + "." + target.getName() + "()%")
      or
      pc.matches("%" + target.getDeclaringType().getName() + "." + target.getName() + "(..)%")
      or
      pc.matches("%" + target.getDeclaringType().getName() + "." + target.getName() + "()%")
      or
      pc.matches("%*." + target.getName() + "(..)%")
      or
      pc.matches("%*." + target.getName() + "()%")
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