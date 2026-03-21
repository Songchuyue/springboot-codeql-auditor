package org.aspectj.lang;

public interface ProceedingJoinPoint extends JoinPoint {
    Object proceed() throws Throwable;
}