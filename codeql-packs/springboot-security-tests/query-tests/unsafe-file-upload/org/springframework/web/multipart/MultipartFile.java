package org.springframework.web.multipart;

import java.io.File;
import java.nio.file.Path;

public interface MultipartFile {
    String getOriginalFilename();

    default void transferTo(Path dest) {
    }

    default void transferTo(File dest) {
    }
}