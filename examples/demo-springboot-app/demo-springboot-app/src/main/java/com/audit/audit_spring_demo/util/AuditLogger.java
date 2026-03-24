package com.audit.audit_spring_demo.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class AuditLogger {
    private static final Logger LOGGER = LoggerFactory.getLogger(AuditLogger.class);

    public void info(String message) {
        LOGGER.info(message);
    }

    public void warn(String message) {
        LOGGER.warn(message);
    }
}
