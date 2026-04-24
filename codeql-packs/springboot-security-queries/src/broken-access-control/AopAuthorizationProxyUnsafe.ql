/**
 * @name Spring authorization AOP cannot intercept proxy-unsafe target
 * @description Authorization AOP appears to target a Spring endpoint, but proxy-based Spring AOP cannot intercept private/static/final target methods.
 * @kind problem
 * @problem.severity warning
 * @security-severity 6.8
 * @precision medium
 * @id scy/java/aop-authorization-proxy-unsafe
 * @tags security
 *       external/cwe/cwe-285
 *       external/cwe/cwe-862
 */

import java
import BrokenAccessControlLib
import common.SpringAopModel

from Method target, Method advice
where
  isSensitiveEndpoint(target) and
  isAuthorizationAopAdvice(advice) and
  adviceMayMatchMethod(advice, target) and
  isProxyUnsafeTargetMethod(target)
select target,
  "Authorization AOP pointcut appears to target this sensitive endpoint, but Spring proxy-based AOP cannot intercept private/static/final target methods."