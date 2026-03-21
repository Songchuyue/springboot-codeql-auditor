package org.aspectj.lang.annotation;

public @interface Before {
    String value() default "";
    String argNames() default "";
}