package org.aspectj.lang.annotation;

public @interface AfterReturning {
    String value() default "";
    String pointcut() default "";
    String returning() default "";
    String argNames() default "";
}