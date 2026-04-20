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
private predicate authLikeMethodName(string n) {
  n.matches("checkAuth%") or
  n.matches("checkPerm%") or
  n.matches("checkPermission%") or
  n.matches("requireAuth%") or
  n.matches("requireRole%") or
  n.matches("verifyAuth%") or
  n.matches("verifyPermission%") or
  n.matches("assertRole%") or
  n.matches("assertPermission%") or
  n.matches("hasRole%") or
  n.matches("hasPermission%") or
  n.matches("isAdmin%")
}

predicate hasAuthorizationGuardCall(Method m) {
  exists(MethodCall mc |
    mc.getEnclosingCallable() = m and
    (
      authLikeMethodName(mc.getMethod().getName())
      or
      exists(RefType t |
        t = mc.getMethod().getDeclaringType() and
        (
          t.getName().matches("%Auth%") or
          t.getName().matches("%Permission%") or
          t.getName().matches("%Security%") or
          t.getName().matches("%AccessControl%")
        )
      )
    )
  )
}