import java
import common.AuthGuards

private predicate isControllerAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RestController") or
  ann.getType().hasQualifiedName("org.springframework.stereotype", "Controller") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "Controller")
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

predicate isSensitiveEndpoint(Method m) {
  isSpringEndpoint(m) and
  (
    sensitiveToken(m.getName()) or
    sensitiveToken(m.getDeclaringType().getName()) or
    sensitiveToken(m.getDeclaringType().getQualifiedName())
  )
}

predicate isProtectedEndpoint(Method m) {
  hasAuthorizationAnnotation(m) or
  hasAuthorizationGuardCall(m)
}

predicate isBrokenAccessControlCandidate(Method m) {
  isSensitiveEndpoint(m) and
  not isProtectedEndpoint(m)
}