import java
import common.AuthGuards
import common.SpringAopModel

private predicate isControllerAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RestController") or
  ann.getType().hasQualifiedName("org.springframework.stereotype", "Controller")
}

private predicate isRequestMappingAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RequestMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "GetMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "PostMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "PutMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "DeleteMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "PatchMapping")
}

private predicate hasControllerType(Method m) {
  exists(RefType t, Annotation ann |
    t = m.getDeclaringType() and
    ann = t.getAnAnnotation() and
    isControllerAnnotation(ann)
  )
}

predicate isSpringEndpoint(Method m) {
  hasControllerType(m) and
  exists(Annotation ann |
    ann = m.getAnAnnotation() and
    isRequestMappingAnnotation(ann)
  )
}

bindingset[s]
private predicate sensitiveToken(string s) {
  s.matches("%admin%") or s.matches("%Admin%") or
  s.matches("%manage%") or s.matches("%Manage%") or
  s.matches("%delete%") or s.matches("%Delete%") or
  s.matches("%update%") or s.matches("%Update%") or
  s.matches("%export%") or s.matches("%Export%") or
  s.matches("%import%") or s.matches("%Import%") or
  s.matches("%config%") or s.matches("%Config%") or
  s.matches("%role%") or s.matches("%Role%") or
  s.matches("%permission%") or s.matches("%Permission%")
}

private predicate mappingValueLooksSensitive(Annotation ann) {
  exists(Expr v |
    v = ann.getValue("value") and
    sensitiveToken(v.toString())
  )
  or
  exists(Expr v |
    v = ann.getValue("path") and
    sensitiveToken(v.toString())
  )
  or
  sensitiveToken(ann.toString())
}

private predicate routeLooksSensitive(Method m) {
  exists(Annotation ann |
    ann = m.getAnAnnotation() and
    isRequestMappingAnnotation(ann) and
    mappingValueLooksSensitive(ann)
  )
  or
  exists(Annotation ann |
    ann = m.getDeclaringType().getAnAnnotation() and
    ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RequestMapping") and
    mappingValueLooksSensitive(ann)
  )
}

predicate isSensitiveEndpoint(Method m) {
  isSpringEndpoint(m) and
  (
    sensitiveToken(m.getName()) or
    sensitiveToken(m.getDeclaringType().getName()) or
    sensitiveToken(m.getDeclaringType().getQualifiedName()) or
    routeLooksSensitive(m)
  )
}

bindingset[n]
private predicate authorizationAopName(string n) {
  n.matches("%Auth%") or
  n.matches("%auth%") or
  n.matches("%Permission%") or
  n.matches("%permission%") or
  n.matches("%Access%") or
  n.matches("%access%") or
  n.matches("%Security%") or
  n.matches("%security%") or
  n.matches("%Role%") or
  n.matches("%role%")
}

/**
 * 识别“权限型 AOP advice”。
 *
 * 三类证据：
 * 1. advice 方法名 / aspect 类名像权限检查；
 * 2. advice 自身带 @PreAuthorize / @Secured / @RolesAllowed；
 * 3. advice 方法体里显式调用权限检查函数。
 */
predicate isAuthorizationAopAdvice(Method advice) {
  isAdviceMethod(advice) and
  (
    authorizationAopName(advice.getName()) or
    authorizationAopName(advice.getDeclaringType().getName()) or
    hasAuthorizationAnnotation(advice) or
    hasAuthorizationGuardCall(advice)
  )
}

/**
 * endpoint 是否被权限 AOP advice 实际可能拦截。
 */
predicate hasAuthorizationAopAdvice(Method m) {
  exists(Method advice |
    isAuthorizationAopAdvice(advice) and
    adviceMayActuallyInterceptMethod(advice, m)
  )
}

predicate isProtectedEndpoint(Method m) {
  hasAuthorizationAnnotation(m) or
  hasAuthorizationGuardCall(m) or
  hasAuthorizationAopAdvice(m)
}

predicate isBrokenAccessControlCandidate(Method m) {
  isSensitiveEndpoint(m) and
  not isProtectedEndpoint(m)
}