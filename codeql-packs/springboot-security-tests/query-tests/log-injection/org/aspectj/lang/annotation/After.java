package org.aspectj.lang.annotation;

public @interface After {
    String value() default "";
    String argNames() default "";
}