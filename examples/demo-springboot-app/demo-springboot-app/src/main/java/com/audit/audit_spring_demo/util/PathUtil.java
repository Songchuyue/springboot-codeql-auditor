package com.audit.audit_spring_demo.util;

public final class PathUtil {
    private PathUtil() {
    }

    public static boolean isSafeRelativePath(String input) {
        return input != null
                && !input.contains("..")
                && !input.contains("/")
                && !input.contains("\\")
                && !input.startsWith(".")
                && !input.isBlank();
    }

    public static String sanitizeFilename(String input) {
        if (input == null) {
            return "";
        }
        return input.replace("..", "")
                .replace("/", "")
                .replace("\\", "")
                .replace("\r", "")
                .replace("\n", "");
    }
}
