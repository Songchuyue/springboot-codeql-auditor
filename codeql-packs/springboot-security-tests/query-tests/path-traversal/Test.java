import java.io.FileInputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class Test {
    private static final String BASE_DIR = "/app/data";

    @GetMapping("/badRead")
    public byte[] badRead(@RequestParam String name) throws Exception {
        return Files.readAllBytes(Paths.get(BASE_DIR, name));
    }

    @GetMapping("/badWrite")
    public void badWrite(@RequestParam String name) throws Exception {
        Files.write(Paths.get(BASE_DIR, name), "x".getBytes());
    }

    @GetMapping("/badStream")
    public int badStream(@RequestParam String name) throws Exception {
        FileInputStream in = new FileInputStream(BASE_DIR + "/" + name);
        int tem = in.read();
        in.close();
        return tem;
    }

    @GetMapping("/badInterprocedural")
    public byte[] badInterprocedural(@RequestParam String name) throws Exception {
        Path p = buildUserControlledPath(name);
        return Files.readAllBytes(p);
    }

    @GetMapping("/goodConstant")
    public byte[] goodConstant() throws Exception {
        return Files.readAllBytes(Paths.get(BASE_DIR, "fixed.txt"));
    }

    @GetMapping("/goodSanitizeFilename")
    public byte[] goodSanitizeFilename(@RequestParam String name) throws Exception {
        String safe = sanitizeFilename(name);
        return Files.readAllBytes(Paths.get(BASE_DIR, safe));
    }

    @GetMapping("/goodGuard")
    public byte[] goodGuard(@RequestParam String name) throws Exception {
        if (!isSafeRelativePath(name)) {
            return new byte[0];
        }
        return Files.readAllBytes(Paths.get(BASE_DIR, name));
    }

    private Path buildUserControlledPath(String name) {
        return Paths.get(BASE_DIR, name);
    }

    private String sanitizeFilename(String name) {
        if (name == null || name.contains("..") || name.contains("/") || name.contains("\\")) {
            return "default.txt";
        }
        return name;
    }

    private boolean isSafeRelativePath(String name) {
        return name != null
            && !name.contains("..")
            && !name.contains("/")
            && !name.contains("\\");
    }
}