package com.songchuyue.bench.upload;

import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

@RestController
@RequestMapping("/bench/upload")
public class UploadController {

    // BENCH: UPLOAD-ORIGINALFILENAME-VULN
    @PostMapping("/original-filename/vuln")
    public String originalFilenameVuln(@RequestParam("file") MultipartFile file) throws IOException {
        Path uploadDir = Path.of("uploads");
        Files.createDirectories(uploadDir);

        Path target = uploadDir.resolve(file.getOriginalFilename());
        file.transferTo(target);
        return target.toString();
    }

    // BENCH: UPLOAD-ORIGINALFILENAME-SAFE
    @PostMapping("/original-filename/safe")
    public String originalFilenameSafe(@RequestParam("file") MultipartFile file) throws IOException {
        Path uploadDir = Path.of("uploads");
        Files.createDirectories(uploadDir);

        String generated = UUID.randomUUID() + ".bin";
        Path target = uploadDir.resolve(generated);
        file.transferTo(target);
        return target.toString();
    }
}
