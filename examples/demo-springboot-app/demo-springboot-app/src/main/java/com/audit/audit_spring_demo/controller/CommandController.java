package com.audit.audit_spring_demo.controller;

import com.audit.audit_spring_demo.service.CommandService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CommandController {
    private final CommandService commandService;

    public CommandController(CommandService commandService) {
        this.commandService = commandService;
    }

    @GetMapping("/cmd/runtimeUnsafe")
    public String runtimeUnsafe(@RequestParam String cmd) throws Exception {
        commandService.runtimeExecUnsafe(cmd);
        return "ok";
    }

    @GetMapping("/cmd/processBuilderListUnsafe")
    public String processBuilderListUnsafe(@RequestParam String cmd) throws Exception {
        commandService.processBuilderListUnsafe(cmd);
        return "ok";
    }

    @GetMapping("/cmd/processBuilderArraysListUnsafe")
    public String processBuilderArraysListUnsafe(@RequestParam String cmd) throws Exception {
        commandService.processBuilderArraysListUnsafe(cmd);
        return "ok";
    }

    @GetMapping("/cmd/onlyAllowDate")
    public String onlyAllowDate(@RequestParam String action) throws Exception {
        commandService.onlyAllowDate(action);
        return "ok";
    }
}
