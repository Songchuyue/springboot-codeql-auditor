import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.springframework.web.multipart.MultipartFile;
import jakarta.servlet.http.Part;

public class Test {
    private static final String BASE = "/uploads";

    void badMultipart(MultipartFile file) throws Exception {
        Path p = Paths.get(BASE, file.getOriginalFilename());
        file.transferTo(p);
    }

    void badPart(Part part) throws Exception {
        new File(BASE, part.getSubmittedFileName());
    }

    void badInterprocedural(MultipartFile file) throws Exception {
        file.transferTo(build(file.getOriginalFilename()));
    }

    void goodConstant(MultipartFile file) throws Exception {
        file.transferTo(Paths.get(BASE, "fixed.txt"));
    }

    void badSanitizeByNameOnly(MultipartFile file) throws Exception {
        String safe = sanitizeFilename(file.getOriginalFilename());
        file.transferTo(Paths.get(BASE, safe));
    }

    void goodGuard(MultipartFile file) throws Exception {
        String name = file.getOriginalFilename();
        if (!isSafeFilename(name)) {
            return;
        }
        file.transferTo(Paths.get(BASE, name));
    }

    private Path build(String name) {
        return Paths.get(BASE, name);
    }

    private String sanitizeFilename(String name) {
        if (name == null) return "default.txt";
        return name.replace("../", "_")
                   .replace("..\\", "_")
                   .replace("/", "_")
                   .replace("\\", "_");
    }

    private boolean isSafeFilename(String name) {
        return name != null
            && !name.contains("..")
            && !name.contains("/")
            && !name.contains("\\");
    }

    void badJavaxPart(javax.servlet.http.Part part) throws Exception {
        new File(BASE, part.getSubmittedFileName());
    }
}