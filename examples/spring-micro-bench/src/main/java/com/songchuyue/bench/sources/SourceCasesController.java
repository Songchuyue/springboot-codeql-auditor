package com.songchuyue.bench.sources;

import com.songchuyue.bench.common.ReqDto;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.util.HtmlUtils;

import java.io.IOException;

// These cases are mainly used to exercise Spring MVC source modeling.
@RestController
@RequestMapping("/bench/src")
public class SourceCasesController {

    // BENCH: SRC-REQPARAM-VULN
    @GetMapping("/request-param/vuln")
    public void requestParamVuln(@RequestParam("q") String q, HttpServletResponse response) throws IOException {
        response.getWriter().write(q);
    }

    // BENCH: SRC-REQPARAM-SAFE
    @GetMapping("/request-param/safe")
    public void requestParamSafe(@RequestParam("q") String q, HttpServletResponse response) throws IOException {
        response.getWriter().write(HtmlUtils.htmlEscape(q));
    }

    // BENCH: SRC-PATHVAR-VULN
    @GetMapping("/path-variable/vuln/{name}")
    public void pathVariableVuln(@PathVariable("name") String name, HttpServletResponse response) throws IOException {
        response.getWriter().write(name);
    }

    // BENCH: SRC-PATHVAR-SAFE
    @GetMapping("/path-variable/safe/{name}")
    public void pathVariableSafe(@PathVariable("name") String name, HttpServletResponse response) throws IOException {
        response.getWriter().write(HtmlUtils.htmlEscape(name));
    }

    // BENCH: SRC-REQUESTBODY-VULN
    @PostMapping("/request-body/vuln")
    public void requestBodyVuln(@RequestBody ReqDto dto, HttpServletResponse response) throws IOException {
        response.getWriter().write(dto.getBody());
    }

    // BENCH: SRC-REQUESTBODY-SAFE
    @PostMapping("/request-body/safe")
    public void requestBodySafe(@RequestBody ReqDto dto, HttpServletResponse response) throws IOException {
        response.getWriter().write(HtmlUtils.htmlEscape(dto.getBody()));
    }
}
