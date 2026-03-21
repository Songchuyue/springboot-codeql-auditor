import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
class Test {
    private static final Logger logger = LoggerFactory.getLogger(Test.class);

    private final AuditLogger auditLogger = new AuditLogger();
    private final LogService logService = new LogService();
    private final UserService userService = new UserService();

    // =========================================================
    // 1. Official baseline should catch
    // =========================================================

    @GetMapping("/badSlf4jParam")
    void badSlf4jParam(@RequestParam String user) {
        logger.warn("login user={}", user);
    }

    @GetMapping("/badSlf4jConcat")
    void badSlf4jConcat(@RequestParam String user) {
        logger.info("login user=" + user);
    }

    // =========================================================
    // 2. Project-specific sink enhancement
    // =========================================================

    @GetMapping("/badWrapperDirect")
    void badWrapperDirect(@RequestParam String user) {
        auditLogger.info(user);
    }

    @GetMapping("/badWrapperFormat")
    void badWrapperFormat(@RequestParam String user) {
        auditLogger.info(String.format("login user=%s", user));
    }

    @GetMapping("/badWrapperBuilder")
    void badWrapperBuilder(@RequestParam String user) {
        StringBuilder sb = new StringBuilder("login user=");
        sb.append(user);
        auditLogger.info(sb.toString());
    }

    // =========================================================
    // 3. Interprocedural
    // =========================================================

    @GetMapping("/badInterprocedural")
    void badInterprocedural(@RequestParam String user) {
        logService.logUser(user);
    }

    // =========================================================
    // 4. Good cases - official sanitizers
    // =========================================================

    @GetMapping("/goodOfficialReplace")
    void goodOfficialReplace(@RequestParam String user) {
        String sanitized = user.replace('\n', '_').replace('\r', '_');
        logger.info("login user={}", sanitized);
    }

    @GetMapping("/goodOfficialRegex")
    void goodOfficialRegex(@RequestParam String user) {
        if (user.matches("\\w*")) {
            logger.warn("login user={}", user);
        }
    }

    // =========================================================
    // 5. Good cases - project sanitizers
    // =========================================================

    @GetMapping("/goodProjectReturnSanitizer")
    void goodProjectReturnSanitizer(@RequestParam String user) {
        auditLogger.info(LogSanitizer.sanitizeForLog(user));
    }

    @GetMapping("/goodProjectGuardSanitizer")
    void goodProjectGuardSanitizer(@RequestParam String user) {
        if (LogSanitizer.isSafeForLog(user)) {
            auditLogger.warn("login user={}", user);
        }
    }

    @GetMapping("/goodConstant")
    void goodConstant() {
        auditLogger.info("login user=system");
    }

    // =========================================================
    // 6. Test helper classes
    // =========================================================

    static class AuditLogger {
        void info(String msg) {
            // project-specific logging wrapper, body intentionally omitted
        }

        void warn(String template, Object arg) {
            // project-specific logging wrapper, body intentionally omitted
        }
    }

    static class LogService {
        private final AuditLogger innerLogger = new AuditLogger();

        void logUser(String user) {
            innerLogger.info("service user=" + user);
        }
    }

    static class LogSanitizer {
        static String sanitizeForLog(String s) {
            // project-specific sanitizer wrapper, modeled in QL
            return s;
        }

        static boolean isSafeForLog(String s) {
            // project-specific guard wrapper, modeled in QL
            return true;
        }
    }

    // =========================================================
    // 1. BAD: JoinPoint.getArgs() 被 advice 直接写日志
    // =========================================================
    @GetMapping("/badAopJoinPoint")
    void badAopJoinPoint(@RequestParam String user) {
        userService.save(user);
    }

    // =========================================================
    // 2. BAD: advice 绑定参数后写项目 logger wrapper
    // =========================================================
    @GetMapping("/badAopBound")
    void badAopBound(@RequestParam String user) {
        userService.audit(user);
    }

    // =========================================================
    // 3. GOOD: advice 中先 sanitizer 再写日志
    // =========================================================
    @GetMapping("/goodAopBoundSanitized")
    void goodAopBoundSanitized(@RequestParam String user) {
        userService.safeAudit(user);
    }

    @Service
    static class UserService {
        void save(String user) { }
        void audit(String user) { }
        void safeAudit(String user) { }
    }

    @Aspect
    @Component
    static class LoggingAspect {
        private static final Logger logger = LoggerFactory.getLogger(LoggingAspect.class);
        private static final AuditLogger auditLogger = new AuditLogger();

        @Before("execution(* TestAopLog.UserService.save(..))")
        public void beforeJoinPoint(JoinPoint jp) {
            logger.info("args={}", jp.getArgs());
        }

        @Before("execution(* TestAopLog.UserService.audit(..)) && args(user)")
        public void beforeBound(String user) {
            auditLogger.info("audit user=" + user);
        }

        @Before("execution(* TestAopLog.UserService.safeAudit(..)) && args(user)")
        public void beforeBoundSafe(String user) {
            String cleaned = user.replace('\n', '_').replace('\r', '_');
            logger.info("safe user={}", cleaned);
        }
    }
}