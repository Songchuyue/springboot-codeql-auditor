/**
 * @name Spring endpoint missing authorization guard
 * @description Sensitive Spring MVC endpoint appears reachable without authorization annotation or explicit authorization guard.
 * @kind problem
 * @problem.severity warning
 * @security-severity 6.3
 * @precision medium
 * @id scy/java/broken-access-control
 * @tags security
 *       external/cwe/cwe-285
 *       external/cwe/cwe-862
 */

import java
import BrokenAccessControlLib

from Method m
where isBrokenAccessControlCandidate(m)
select m,
  "Sensitive Spring endpoint appears reachable without authorization annotation or explicit authorization guard."