package com.audit.audit_spring_demo.aspect;

import com.audit.audit_spring_demo.util.AuditLogger;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.springframework.stereotype.Component;

import java.util.Arrays;

@Aspect
@Component
public class RequestLoggingAspect {
    private final AuditLogger auditLogger;

    public RequestLoggingAspect(AuditLogger auditLogger) {
        this.auditLogger = auditLogger;
    }

    @Before("execution(* com.audit.audit_spring_demo.service.GreetingService.serviceMethodForAspect(..))")
    public void logArgs(JoinPoint joinPoint) {
        auditLogger.info("aop args=" + Arrays.toString(joinPoint.getArgs()));
    }
}
