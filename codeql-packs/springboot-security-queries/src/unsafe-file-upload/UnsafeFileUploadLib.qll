import java
import semmle.code.java.dataflow.DataFlow
import common.CommonTaintSteps
import common.FileSystemSinks

private predicate isMultipartFilenameGetter(Method m) {
  m.hasQualifiedName("org.springframework.web.multipart", "MultipartFile", "getOriginalFilename")
  or
  m.hasQualifiedName("jakarta.servlet.http", "Part", "getSubmittedFileName")
  or
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

predicate isUnsafeUploadAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
  isCommonStringAssemblyStep(pred, succ)
}