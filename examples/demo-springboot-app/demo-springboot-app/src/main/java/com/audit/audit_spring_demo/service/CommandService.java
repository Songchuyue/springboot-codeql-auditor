package com.audit.audit_spring_demo.service;

import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;

@Service
public class CommandService {
    public Process runtimeExecUnsafe(String cmd) throws Exception {
        return Runtime.getRuntime().exec(cmd);
    }

    public Process processBuilderListUnsafe(String cmd) throws Exception {
        List<String> argv = List.of("sh", "-c", cmd);
        return new ProcessBuilder(argv).start();
    }

    public Process processBuilderArraysListUnsafe(String cmd) throws Exception {
        return new ProcessBuilder(Arrays.asList("sh", "-c", cmd)).start();
    }

    public Process onlyAllowDate(String action) throws Exception {
        if (!"date".equals(action)) {
            throw new IllegalArgumentException("blocked");
        }
        return new ProcessBuilder(List.of("sh", "-c", action)).start();
    }
}
