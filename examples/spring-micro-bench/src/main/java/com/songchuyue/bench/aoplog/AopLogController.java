package com.songchuyue.bench.aoplog;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/bench/log/aop-joinpoint")
public class AopLogController {
    private final AopLogService service;

    public AopLogController(AopLogService service) {
        this.service = service;
    }

    @GetMapping("/vuln")
    public String vuln(@RequestParam("secret") String secret) {
        return service.processVuln(secret);
    }

    @GetMapping("/safe")
    public String safe(@RequestParam("secret") String secret) {
        return service.processSafe(secret);
    }
}
