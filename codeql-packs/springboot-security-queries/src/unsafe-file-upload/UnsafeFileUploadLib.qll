import java
import semmle.code.java.dataflow.DataFlow

import common.CommonTaintSteps
import common.FileSystemSinks

private predicate isMultipartFilenameGetter(Method m) {
  m.hasQualifiedName("org.springframework.web.multipart", "MultipartFile", "getOriginalFilename") or
  m.hasQualifiedName("jakarta.servlet.http", "Part", "getSubmittedFileName") or
  m.hasQualifiedName("javax.servlet.http", "Part", "getSubmittedFileName")
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

/** 通用规则里不要按方法名直接信任 guard。需要项目特定建模时，再单独加。 */
predicate isUnsafeUploadGuardBarrierNode(DataFlow::Node node) { none() }

predicate isUnsafeUploadAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  isCommonStringAssemblyStep(pred, succ)
}