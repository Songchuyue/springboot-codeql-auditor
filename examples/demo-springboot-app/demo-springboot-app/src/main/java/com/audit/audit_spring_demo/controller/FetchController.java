package com.audit.audit_spring_demo.controller;

import com.audit.audit_spring_demo.service.SsrfService;
import org.springframework.http.RequestEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;

@RestController
public class FetchController {
    private final SsrfService ssrfService;

    public FetchController(SsrfService ssrfService) {
        this.ssrfService = ssrfService;
    }

    @GetMapping("/fetch/openStreamUnsafe")
    public String openStreamUnsafe(@RequestParam String url) throws Exception {
        return ssrfService.openStreamUnsafe(url);
    }

    @GetMapping("/fetch/restClientBaseUrlUnsafe")
    public String restClientBaseUrlUnsafe(@RequestParam String baseUrl) {
        return ssrfService.restClientBaseUrlUnsafe(baseUrl);
    }

    @GetMapping("/fetch/restClientUriVariableUnsafe")
    public String restClientUriVariableUnsafe(@RequestParam String host) {
        return ssrfService.restClientUriVariableUnsafe(host);
    }

    @GetMapping("/fetch/requestEntityBuilderUnsafe")
    public RequestEntity<Void> requestEntityBuilderUnsafe(@RequestParam String host) {
        return ssrfService.requestEntityBuilderUnsafe(host);
    }

    @GetMapping("/fetch/restClientBuilderBaseUrlUnsafe")
    public String restClientBuilderBaseUrlUnsafe(@RequestParam String baseUrl) {
        return ssrfService.restClientBuilderBaseUrlUnsafe(URI.create(baseUrl));
    }

    @GetMapping("/fetch/onlyAllowExampleCom")
    public String onlyAllowExampleCom(@RequestParam String url) {
        return ssrfService.onlyAllowExampleCom(url);
    }
}
