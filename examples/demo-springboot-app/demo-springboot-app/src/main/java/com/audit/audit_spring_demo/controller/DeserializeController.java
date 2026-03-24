package com.audit.audit_spring_demo.controller;

import com.audit.audit_spring_demo.service.DeserializeService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DeserializeController {
    private final DeserializeService deserializeService;

    public DeserializeController(DeserializeService deserializeService) {
        this.deserializeService = deserializeService;
    }

    @PostMapping("/deserialize/base64Unsafe")
    public Object base64Unsafe(@RequestBody String payload) throws Exception {
        return deserializeService.deserializeBase64Unsafe(payload);
    }
}
