package com.audit.audit_spring_demo.controller;

import com.audit.audit_spring_demo.service.HtmlService;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ViewController {
    private final HtmlService htmlService;

    public ViewController(HtmlService htmlService) {
        this.htmlService = htmlService;
    }

    @GetMapping("/xss/directUnsafe")
    public void directUnsafe(@RequestParam String q, HttpServletResponse response) throws Exception {
        response.setContentType("text/html;charset=UTF-8");
        response.getWriter().println(htmlService.directUnsafe(q));
    }

    @GetMapping("/xss/builderUnsafe")
    public void builderUnsafe(@RequestParam String q, HttpServletResponse response) throws Exception {
        response.setContentType("text/html;charset=UTF-8");
        response.getWriter().println(htmlService.builderUnsafe(q));
    }

    @GetMapping("/xss/formatUnsafe")
    public void formatUnsafe(@RequestParam String q, HttpServletResponse response) throws Exception {
        response.setContentType("text/html;charset=UTF-8");
        response.getWriter().println(htmlService.formatUnsafe(q));
    }

    @GetMapping("/xss/safe")
    public void safe(@RequestParam String q, HttpServletResponse response) throws Exception {
        response.setContentType("text/html;charset=UTF-8");
        response.getWriter().println(htmlService.safe(q));
    }
}
