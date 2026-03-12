import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.frameworks.spring.SpringController

private predicate isFallbackSpringControllerAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RestController") or
  ann.getType().hasQualifiedName("org.springframework.stereotype", "Controller")
}

private predicate isFallbackSpringRequestHandlerAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RequestMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "GetMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "PostMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "PutMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "DeleteMapping") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "PatchMapping")
}

private predicate isFallbackSpringMvcParameterAnnotation(Annotation ann) {
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RequestParam") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "PathVariable") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RequestHeader") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "CookieValue") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "MatrixVariable") or
  ann.getType().hasQualifiedName("org.springframework.web.bind.annotation", "RequestBody")
}

private predicate isFallbackAnnotatedSpringMvcSourceNode(DataFlow::Node src) {
  exists(Parameter p, Method m |
    src = DataFlow::parameterNode(p) and
    p.fromSource() and
    m = p.getCallable() and
    exists(Annotation cAnn |
      cAnn = m.getDeclaringType().getAnAnnotation() and
      isFallbackSpringControllerAnnotation(cAnn)
    ) and
    exists(Annotation mAnn |
      mAnn = m.getAnAnnotation() and
      isFallbackSpringRequestHandlerAnnotation(mAnn)
    ) and
    exists(Annotation pAnn |
      pAnn = p.getAnAnnotation() and
      isFallbackSpringMvcParameterAnnotation(pAnn)
    )
  )
}

private predicate isOfficialSpringMvcSourceNode(DataFlow::Node src) {
  exists(SpringRequestMappingParameter p |
    src = DataFlow::parameterNode(p) and
    p.isTaintedInput()
  )
}

predicate isSpringMvcSourceNode(DataFlow::Node src) {
  isOfficialSpringMvcSourceNode(src)
  or
  isFallbackAnnotatedSpringMvcSourceNode(src)
}

/** Extension point for project-specific sanitizers. */
predicate isProjectSqlSanitizer(DataFlow::Node node) { none() }

/** Extension point for project-specific extra taint steps. */
predicate isProjectSqlFlowStep(DataFlow::Node n1, DataFlow::Node n2) { none() }