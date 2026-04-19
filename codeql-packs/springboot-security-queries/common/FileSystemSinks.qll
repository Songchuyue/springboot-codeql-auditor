import java
import semmle.code.java.dataflow.DataFlow

private predicate isPathLikeType(Type t) {
  exists(RefType rt |
    rt = t and
    (
      rt.hasQualifiedName("java.lang", "String") or
      rt.hasQualifiedName("java.io", "File") or
      rt.hasQualifiedName("java.nio.file", "Path")
    )
  )
}

private predicate isPathLikeExpr(Expr e) {
  isPathLikeType(e.getType())
}

private predicate isFileCtor(Constructor c) {
  c.getDeclaringType().hasQualifiedName("java.io", "File")
}

private predicate isFileIoCtor(Constructor c) {
  c.getDeclaringType().hasQualifiedName("java.io", "FileInputStream") or
  c.getDeclaringType().hasQualifiedName("java.io", "FileOutputStream") or
  c.getDeclaringType().hasQualifiedName("java.io", "FileReader") or
  c.getDeclaringType().hasQualifiedName("java.io", "FileWriter") or
  c.getDeclaringType().hasQualifiedName("java.io", "RandomAccessFile")
}

predicate isFilePathConstructionNode(DataFlow::Node node) {
  exists(Call call, Constructor c |
    call.getCallee() = c and
    isFileCtor(c) and
    node = DataFlow::exprNode(call.getAnArgument())
  )
  or
  exists(MethodCall mc |
    (
      mc.getMethod().hasQualifiedName("java.nio.file", "Paths", "get") or
      mc.getMethod().hasQualifiedName("java.nio.file", "Path", "of")
    ) and
    node = DataFlow::exprNode(mc.getAnArgument())
  )
  or
  exists(MethodCall mc |
    (
      mc.getMethod().hasQualifiedName("java.nio.file", "Path", "resolve") or
      mc.getMethod().hasQualifiedName("java.nio.file", "Path", "resolveSibling")
    ) and
    (
      node = DataFlow::exprNode(mc.getQualifier())
      or
      node = DataFlow::exprNode(mc.getArgument(0))
    )
  )
}

predicate isFileReadOrWriteDestinationSink(DataFlow::Node sink) {
  exists(Call call, Constructor c, Expr arg |
    call.getCallee() = c and
    isFileIoCtor(c) and
    arg = call.getArgument(0) and
    isPathLikeExpr(arg) and
    sink = DataFlow::exprNode(arg)
  )
  or
  exists(MethodCall mc, Expr arg |
    mc.getMethod().hasQualifiedName("java.nio.file", "Files", "write") and
    arg = mc.getArgument(0) and
    isPathLikeExpr(arg) and
    sink = DataFlow::exprNode(arg)
  )
  or
  exists(MethodCall mc, Expr arg |
    mc.getMethod().hasQualifiedName("java.nio.file", "Files", "writeString") and
    arg = mc.getArgument(0) and
    isPathLikeExpr(arg) and
    sink = DataFlow::exprNode(arg)
  )
  or
  exists(MethodCall mc, Expr arg |
    mc.getMethod().hasQualifiedName("java.nio.file", "Files", "newInputStream") and
    arg = mc.getArgument(0) and
    isPathLikeExpr(arg) and
    sink = DataFlow::exprNode(arg)
  )
  or
  exists(MethodCall mc, Expr arg |
    mc.getMethod().hasQualifiedName("java.nio.file", "Files", "newOutputStream") and
    arg = mc.getArgument(0) and
    isPathLikeExpr(arg) and
    sink = DataFlow::exprNode(arg)
  )
  or
  exists(MethodCall mc, Expr arg |
    mc.getMethod().hasQualifiedName("java.nio.file", "Files", "newBufferedReader") and
    arg = mc.getArgument(0) and
    isPathLikeExpr(arg) and
    sink = DataFlow::exprNode(arg)
  )
  or
  exists(MethodCall mc, Expr arg |
    mc.getMethod().hasQualifiedName("java.nio.file", "Files", "newBufferedWriter") and
    arg = mc.getArgument(0) and
    isPathLikeExpr(arg) and
    sink = DataFlow::exprNode(arg)
  )
  or
  exists(MethodCall mc, Expr arg |
    mc.getMethod().hasQualifiedName("java.nio.file", "Files", "copy") and
    arg = mc.getArgument(1) and
    isPathLikeExpr(arg) and
    sink = DataFlow::exprNode(arg)
  )
  or
  exists(MethodCall mc, Expr arg |
    mc.getMethod().hasQualifiedName("java.nio.file", "Files", "move") and
    arg = mc.getArgument(1) and
    isPathLikeExpr(arg) and
    sink = DataFlow::exprNode(arg)
  )
  or
  exists(MethodCall mc, Expr arg |
    mc.getMethod().hasQualifiedName("org.springframework.web.multipart", "MultipartFile", "transferTo") and
    arg = mc.getArgument(0) and
    isPathLikeExpr(arg) and
    sink = DataFlow::exprNode(arg)
  )
}

predicate isAnyFileSystemSink(DataFlow::Node sink) {
  isFilePathConstructionNode(sink) or
  isFileReadOrWriteDestinationSink(sink)
}