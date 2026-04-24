/**
 * @name Spring authorization AOP bypassed by self-invocation
 * @description A method matched by authorization AOP is invoked through self-invocation, which Spring proxy-based AOP does not intercept.
 * @kind problem
 * @problem.severity warning
 * @security-severity 6.8
 * @precision medium
 * @id scy/java/aop-authorization-self-invocation
 * @tags security
 *       external/cwe/cwe-285
 *       external/cwe/cwe-862
 */

import java
import BrokenAccessControlLib
import common.SpringAopModel

from Method caller, MethodCall call, Method callee, Method advice
where
  isAdvisedSelfInvocation(caller, call, callee, advice) and
  isAuthorizationAopAdvice(advice)
select call,
  "This self-invocation calls a method matched by authorization AOP, but Spring proxy-based AOP will not intercept calls made inside the target object."