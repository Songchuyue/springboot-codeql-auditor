package com.audit.audit_spring_demo.service;

import org.springframework.stereotype.Service;
import org.springframework.web.util.HtmlUtils;

@Service
public class HtmlService {
    public String directUnsafe(String q) {
        return "<div>" + q + "</div>";
    }

    public String builderUnsafe(String q) {
        StringBuilder html = new StringBuilder();
        html.append("<div class='msg'>");
        html.append(q);
        html.append("</div>");
        return html.toString();
    }

    public String formatUnsafe(String q) {
        return String.format("<span>%s</span>", q);
    }

    public String safe(String q) {
        return "<div>" + HtmlUtils.htmlEscape(q) + "</div>";
    }
}
