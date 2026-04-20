import java

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
  t.getName().matches("%Authorization%")
}

private predicate isLocalAuthHelperCall(Method m, MethodCall mc) {
  mc.getEnclosingCallable() = m and
  mc.getMethod().getDeclaringType() = m.getDeclaringType() and
  authLikeEnforcingMethodName(mc.getMethod().getName())
}

private predicate isGuardServiceCall(Method m, MethodCall mc) {
  mc.getEnclosingCallable() = m and
  authLikeGuardType(mc.getMethod().getDeclaringType()) and
  authLikeEnforcingMethodName(mc.getMethod().getName())
}

predicate hasAuthorizationGuardCall(Method m) {
  exists(MethodCall mc |
    isLocalAuthHelperCall(m, mc)
    or
    isGuardServiceCall(m, mc)
  )
}