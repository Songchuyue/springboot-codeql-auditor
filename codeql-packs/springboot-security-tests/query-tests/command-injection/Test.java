import java.io.IOException;
import java.util.Arrays;
import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
class Test {
    private final CommandService commandService = new CommandService();

    // =========================================================
    // 1. Official baseline should catch
    // =========================================================

    @GetMapping("/badRuntimeExec")
    void badRuntimeExec(@RequestParam String cmd) throws IOException {
        Runtime.getRuntime().exec(cmd);
    }

    @GetMapping("/badRuntimeConcat")
    void badRuntimeConcat(@RequestParam String file) throws IOException {
        Runtime.getRuntime().exec("grep " + file + " /tmp/app.log");
    }

    @GetMapping("/badRuntimeBuilder")
    void badRuntimeBuilder(@RequestParam String file) throws IOException {
        StringBuilder sb = new StringBuilder("grep ");
        sb.append(file);
        sb.append(" /tmp/app.log");
        Runtime.getRuntime().exec(sb.toString());
    }

    @GetMapping("/badRuntimeFormat")
    void badRuntimeFormat(@RequestParam String file) throws IOException {
        String cmd = String.format("grep %s /tmp/app.log", file);
        Runtime.getRuntime().exec(cmd);
    }

    // =========================================================
    // 2. Project-specific enhancement:
    //    ProcessBuilder(List<String>) / pb.command(List<String>)
    // =========================================================

    @GetMapping("/badProcessBuilderListOf")
    void badProcessBuilderListOf(@RequestParam String cmd) throws IOException {
        List<String> argv = List.of("sh", "-c", cmd);
        new ProcessBuilder(argv).start();
    }

    @GetMapping("/badProcessBuilderAsList")
    void badProcessBuilderAsList(@RequestParam String cmd) throws IOException {
        List<String> argv = Arrays.asList("cmd.exe", "/c", cmd);
        new ProcessBuilder(argv).start();
    }

    @GetMapping("/badProcessBuilderCommandList")
    void badProcessBuilderCommandList(@RequestParam String cmd) throws IOException {
        ProcessBuilder pb = new ProcessBuilder();
        pb.command(List.of("sh", "-c", cmd));
        pb.start();
    }

    // =========================================================
    // 3. Interprocedural
    // =========================================================

    @GetMapping("/badInterprocedural")
    void badInterprocedural(@RequestParam String cmd) throws IOException {
        commandService.run(cmd);
    }

    // =========================================================
    // 4. Good cases
    // =========================================================

    @GetMapping("/goodConstant")
    void goodConstant() throws IOException {
        Runtime.getRuntime().exec("whoami");
    }

    // @GetMapping("/goodAllowlisted")
    // void goodAllowlisted(@RequestParam String cmd) throws IOException {
    //     if ("whoami".equals(cmd)) {
    //         Runtime.getRuntime().exec(cmd);
    //     }
    // }

    // @GetMapping("/goodAllowlistedReverse")
    // void goodAllowlistedReverse(@RequestParam String cmd) throws IOException {
    //     if (cmd.equals("dir")) {
    //         Runtime.getRuntime().exec(cmd);
    //     }
    // }

    // =========================================================
    // 5. Nested helpers
    // =========================================================

    static class CommandService {
        void run(String cmd) throws IOException {
            new CommandRepository().exec(cmd);
        }
    }

    static class CommandRepository {
        void exec(String cmd) throws IOException {
            Runtime.getRuntime().exec(cmd);
        }
    }
}