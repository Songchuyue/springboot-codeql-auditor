package com.audit.audit_spring_demo.util;

import java.nio.file.Files;
import java.nio.file.Path;

public final class TextFileReader {
    private TextFileReader() {
    }

    public static String readAll(Path path) throws Exception {
        return Files.readString(path);
    }
}
