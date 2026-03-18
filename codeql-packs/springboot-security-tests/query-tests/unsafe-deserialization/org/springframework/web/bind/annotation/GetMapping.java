package org.springframework.web.bind.annotation;

@RequestMapping
public @interface GetMapping {
    String value() default "";
}