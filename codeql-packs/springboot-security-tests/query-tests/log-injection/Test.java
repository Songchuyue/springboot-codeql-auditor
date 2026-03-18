import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
class Test {
    private static final Logger logger = LoggerFactory.getLogger(Test.class);

    private final AuditLogger auditLogger = new AuditLogger();
    private final LogService logService = new LogService();

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
}