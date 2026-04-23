import java
import common.SpringBeanModel

private predicate isMethodSecurityAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.security.access.prepost", "PreAuthorize") or
  ann.getType().hasQualifiedName("org.springframework.security.access.annotation", "Secured") or
  ann.getType().hasQualifiedName("jakarta.annotation.security", "RolesAllowed") or
  ann.getType().hasQualifiedName("javax.annotation.security", "RolesAllowed")
}

predicate hasAuthorizationAnnotation(Method m) {
  exists(Annotation ann |
    ann = m.getAnAnnotation() and
    isMethodSecurityAnnotation(ann)
  )
  or
  exists(RefType t, Annotation ann |
    t = m.getDeclaringType() and
    ann = t.getAnAnnotation() and
    isMethodSecurityAnnotation(ann)
  )
}

bindingset[n]
private predicate authLikeEnforcingMethodName(string n) {
  n.matches("checkAuth%") or
  n.matches("checkPerm%") or
  n.matches("checkPermission%") or
  n.matches("requireAuth%") or
  n.matches("requireRole%") or
  n.matches("requirePermission%") or
  n.matches("verifyAuth%") or
  n.matches("verifyPermission%") or
  n.matches("assertRole%") or
  n.matches("assertPermission%") or
  n.matches("authorize%") or
  n.matches("enforce%")
}

private predicate authLikeGuardType(RefType t) {
  t.getName().matches("%Auth%") or
  t.getName().matches("%Permission%") or
  t.getName().matches("%AccessControl%") or
  t.getName().matches("%Authorization%") or
  t.getName().matches("%Role%") or
  t.getName().matches("%Security%")
}

private predicate isLocalAuthHelperCall(Method m, MethodCall mc) {
  mc.getEnclosingCallable() = m and
  mc.getMethod().getDeclaringType() = m.getDeclaringType() and
  authLikeEnforcingMethodName(mc.getMethod().getName())
}

private predicate isDirectGuardServiceCall(Method m, MethodCall mc) {
  mc.getEnclosingCallable() = m and
  authLikeGuardType(mc.getMethod().getDeclaringType()) and
  authLikeEnforcingMethodName(mc.getMethod().getName())
}

/**
 * 新增：通过注入字段发起的 guard 调用
 * 例如 this.permissionChecker.requireRole(...)
 */
private predicate isInjectedGuardServiceCall(Method m, MethodCall mc) {
  mc.getEnclosingCallable() = m and
  authLikeEnforcingMethodName(mc.getMethod().getName()) and
  exists(RefType impl |
    injectedFieldReceiverCallMayResolveToBeanType(mc, impl) and
    authLikeGuardType(impl)
  )
}

/**
 * 新增：controller -> injected service -> service 内部 guard
 * 这里只做一跳近似，不做深递归
 */
private predicate injectedServiceMethodHasGuard(Method callee) {
  hasAuthorizationAnnotation(callee)
  or
  exists(MethodCall inner |
    isLocalAuthHelperCall(callee, inner)
    or
    isDirectGuardServiceCall(callee, inner)
    or
    isInjectedGuardServiceCall(callee, inner)
  )
}

private predicate isGuardedInjectedServiceDelegation(Method m, MethodCall mc) {
  mc.getEnclosingCallable() = m and
  exists(RefType impl, Method callee |
    injectedFieldReceiverCallMayResolveToBeanType(mc, impl) and
    callee.getDeclaringType() = impl and
    callee.hasName(mc.getMethod().getName()) and
    callee.getNumberOfParameters() = mc.getMethod().getNumberOfParameters() and
    injectedServiceMethodHasGuard(callee)
  )
}

predicate hasAuthorizationGuardCall(Method m) {
  exists(MethodCall mc |
    isLocalAuthHelperCall(m, mc)
    or
    isDirectGuardServiceCall(m, mc)
    or
    isInjectedGuardServiceCall(m, mc)
    or
    isGuardedInjectedServiceDelegation(m, mc)
  )
}