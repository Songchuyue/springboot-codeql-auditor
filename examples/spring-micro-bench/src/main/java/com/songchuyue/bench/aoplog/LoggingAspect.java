package com.songchuyue.bench.aoplog;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.Arrays;

@Aspect
@Component
public class LoggingAspect {
    private static final Logger LOGGER = LoggerFactory.getLogger(LoggingAspect.class);

    // BENCH: LOG-AOP-JOINPOINT-VULN
    @Around("execution(* com.songchuyue.bench.aoplog.AopLogService.processVuln(..))")
    public Object logArgsVuln(ProceedingJoinPoint jp) throws Throwable {
        LOGGER.info("args={}", Arrays.toString(jp.getArgs()));
        return jp.proceed();
    }

    // BENCH: LOG-AOP-JOINPOINT-SAFE
    @Around("execution(* com.songchuyue.bench.aoplog.AopLogService.processSafe(..))")
    public Object logArgsSafe(ProceedingJoinPoint jp) throws Throwable {
        LOGGER.info("fixed-log");
        return jp.proceed();
    }
}
