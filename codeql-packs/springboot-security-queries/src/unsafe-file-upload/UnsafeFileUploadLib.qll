import java
import semmle.code.java.controlflow.Guards
import semmle.code.java.dataflow.DataFlow

import common.CommonTaintSteps
import common.FileSystemSinks

private predicate isMultipartFilenameGetter(Method m) {
  m.hasQualifiedName("org.springframework.web.multipart", "MultipartFile", "getOriginalFilename") or
  m.hasQualifiedName("jakarta.servlet.http", "Part", "getSubmittedFileName") or
  m.hasQualifiedName("javax.servlet.http", "Part", "getSubmittedFileName")
}

private predicate safeFilenameGuard(Guard g, Expr e, boolean branch) {
  exists(MethodCall mc |
    g = mc and
    branch = true and
    e = mc.getArgument(0) and
    (
      mc.getMethod().hasName("isSafeFilename") or
      mc.getMethod().hasName("isSafeRelativePath")
    )
  )
}

predicate isUnsafeUploadSourceNode(DataFlow::Node src) {
  exists(MethodCall mc |
    isMultipartFilenameGetter(mc.getMethod()) and
    src = DataFlow::exprNode(mc)
  )
}

predicate isUnsafeUploadSinkNode(DataFlow::Node sink) {
  isAnyFileSystemSink(sink)
}

// 通用规则里不要按方法名直接判定 sanitizer
predicate isUnsafeUploadSanitizerNode(DataFlow::Node node) {
  exists(int i |
    i = 0 and
    i = 1 and
    node = node
  )
}

predicate isUnsafeUploadGuardBarrierNode(DataFlow::Node node) {
  node = DataFlow::BarrierGuard<safeFilenameGuard/3>::getABarrierNode()
}

predicate isUnsafeUploadAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  isCommonStringAssemblyStep(pred, succ)
}