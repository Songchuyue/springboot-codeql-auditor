package com.audit.audit_spring_demo.controller;

import com.audit.audit_spring_demo.service.GreetingService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class LogController {
    private final GreetingService greetingService;

    public LogController(GreetingService greetingService) {
        this.greetingService = greetingService;
    }

    @GetMapping("/log/wrapperUnsafe")
    public String wrapperUnsafe(@RequestParam String name) {
        return greetingService.wrapperLogUnsafe(name);
    }

    @GetMapping("/log/wrapperSafe")
    public String wrapperSafe(@RequestParam String name) {
        return greetingService.wrapperLogSafe(name);
    }

    @GetMapping("/log/aopUnsafe")
    public String aopUnsafe(@RequestParam String payload) {
        return greetingService.serviceMethodForAspect(payload);
    }
}
