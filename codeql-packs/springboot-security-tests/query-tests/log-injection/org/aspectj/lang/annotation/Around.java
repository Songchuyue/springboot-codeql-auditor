package org.aspectj.lang.annotation;

public @interface Around {
    String value() default "";
    String argNames() default "";
}