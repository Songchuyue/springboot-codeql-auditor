import java
import semmle.code.java.dataflow.DataFlow

bindingset[s]
private predicate sensitiveName(string s) {
  s.matches("%password%") or
  s.matches("%Password%") or
  s.matches("%passwd%") or
  s.matches("%Passwd%") or
  s.matches("%pwd%") or
  s.matches("%Pwd%") or
  s.matches("%secret%") or
  s.matches("%Secret%") or
  s.matches("%token%") or
  s.matches("%Token%") or
  s.matches("%apiKey%") or
  s.matches("%ApiKey%") or
  s.matches("%accessToken%") or
  s.matches("%AccessToken%") or
  s.matches("%refreshToken%") or
  s.matches("%RefreshToken%") or
  s.matches("%credential%") or
  s.matches("%Credential%") or
  s.matches("%privateKey%") or
  s.matches("%PrivateKey%") or
  s.matches("%sessionId%") or
  s.matches("%SessionId%") or
  s.matches("%sessionKey%") or
  s.matches("%SessionKey%") or
  s.matches("%phone%") or
  s.matches("%Phone%") or
  s.matches("%mobile%") or
  s.matches("%Mobile%") or
  s.matches("%idCard%") or
  s.matches("%IdCard%")
}

bindingset[s]
predicate isSensitiveName(string s) {
  sensitiveName(s)
}

predicate isSensitiveDataSourceNode(DataFlow::Node src) {
  exists(Parameter p |
    sensitiveName(p.getName()) and
    src = DataFlow::parameterNode(p)
  )
  or
  exists(Field f, FieldAccess fa |
    fa.getField() = f and
    sensitiveName(f.getName()) and
    src = DataFlow::exprNode(fa)
  )
  or
  exists(MethodCall mc |
    mc.getMethod().getNumberOfParameters() = 0 and
    mc.getMethod().getName().matches("get%") and
    sensitiveName(mc.getMethod().getName()) and
    src = DataFlow::exprNode(mc)
  )
  or
  exists(MethodCall mc, StringLiteral lit |
    (
      mc.getMethod().hasQualifiedName("org.springframework.core.env", "Environment", "getProperty") or
      mc.getMethod().hasQualifiedName("org.springframework.core.env", "PropertyResolver", "getProperty") or
      mc.getMethod().hasQualifiedName("java.lang", "System", "getProperty") or
      mc.getMethod().hasQualifiedName("java.lang", "System", "getenv")
    ) and
    lit = mc.getArgument(0) and
    sensitiveName(lit.getValue()) and
    src = DataFlow::exprNode(mc)
  )
}