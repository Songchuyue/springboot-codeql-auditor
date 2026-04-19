class Test {
    private final AuditLogger auditLogger = new AuditLogger();
    private String accessToken;

    void badParam(String password) {
        auditLogger.info(password);
    }

    void badField() {
        auditLogger.warn(accessToken);
    }

    void badGetter(Credential c) {
        auditLogger.info("pwd=" + c.getPassword());
    }

    void badBuilder(Credential c) {
        StringBuilder sb = new StringBuilder("pwd=");
        sb.append(c.getPassword());
        auditLogger.info(sb.toString());
    }

    void badFormat(Credential c) {
        auditLogger.info(String.format("pwd=%s", c.getPassword()));
    }

    void badResponse(String token, Response resp) {
        resp.getWriter().write(token);
    }

    void goodConstant() {
        auditLogger.info("ok");
    }

    void goodNonSensitive(String userName) {
        auditLogger.info(userName);
    }

    static class Credential {
        String getPassword() {
            return null;
        }
    }

    static class AuditLogger {
        void info(String msg) {
        }

        void warn(String msg) {
        }
    }

    static class Response {
        Writer getWriter() {
            return null;
        }
    }

    static class Writer {
        void write(String s) {
        }
    }
}