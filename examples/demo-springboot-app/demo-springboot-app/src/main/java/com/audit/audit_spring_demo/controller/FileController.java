package com.audit.audit_spring_demo.controller;

import com.audit.audit_spring_demo.service.FileService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class FileController {
    private final FileService fileService;

    public FileController(FileService fileService) {
        this.fileService = fileService;
    }

    @GetMapping("/file/readUnsafe")
    public String readUnsafe(@RequestParam String name) throws Exception {
        return fileService.readUnsafe(name);
    }

    @GetMapping("/file/readSafe")
    public String readSafe(@RequestParam String name) throws Exception {
        return fileService.readSafe(name);
    }
}
