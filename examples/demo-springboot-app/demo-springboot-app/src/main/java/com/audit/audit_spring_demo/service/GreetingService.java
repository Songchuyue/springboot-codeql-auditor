package com.audit.audit_spring_demo.service;

import com.audit.audit_spring_demo.util.AuditLogger;
import org.springframework.stereotype.Service;

@Service
public class GreetingService {
    private final AuditLogger auditLogger;

    public GreetingService(AuditLogger auditLogger) {
        this.auditLogger = auditLogger;
    }

    public String wrapperLogUnsafe(String name) {
        auditLogger.info("wrapper user=" + name);
        return "hello, " + name;
    }

    public String wrapperLogSafe(String name) {
        if (!hasNoLineBreaks(name)) {
            throw new IllegalArgumentException("invalid log content");
        }
        auditLogger.info("wrapper user=" + removeLineBreaks(name));
        return "hello, " + name;
    }

    public boolean hasNoLineBreaks(String input) {
        return input != null && !input.contains("\n") && !input.contains("\r");
    }

    public String removeLineBreaks(String input) {
        return input == null ? "" : input.replace("\r", "").replace("\n", "");
    }

    public String serviceMethodForAspect(String payload) {
        return "service:" + payload;
    }
}
