package com.audit.audit_spring_demo.service;

import com.audit.audit_spring_demo.util.PathUtil;
import com.audit.audit_spring_demo.util.TextFileReader;
import org.springframework.stereotype.Service;

import java.nio.file.Path;
import java.nio.file.Paths;

@Service
public class FileService {
    private static final String BASE_DIR = "uploads";

    public String readUnsafe(String name) throws Exception {
        Path path = Paths.get(BASE_DIR, name);
        return TextFileReader.readAll(path);
    }

    public String readSafe(String name) throws Exception {
        if (!PathUtil.isSafeRelativePath(name)) {
            throw new IllegalArgumentException("invalid file name");
        }
        String safe = PathUtil.sanitizeFilename(name);
        Path path = Paths.get(BASE_DIR, safe);
        return TextFileReader.readAll(path);
    }
}
