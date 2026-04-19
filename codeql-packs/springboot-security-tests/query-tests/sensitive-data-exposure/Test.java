import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
class Test {
    private static final Logger logger = LoggerFactory.getLogger(Test.class);

    private String accessToken;

    @GetMapping("/badParam")
    void badParam(@RequestParam String password) {
        logger.info(password);
    }

    @GetMapping("/badField")
    void badField() {
        logger.warn(accessToken);
    }

    @GetMapping("/badGetter")
    void badGetter(Credential c) {
        logger.info("pwd=" + c.getPassword());
    }

    @GetMapping("/badBuilder")
    void badBuilder(Credential c) {
        StringBuilder sb = new StringBuilder("pwd=");
        sb.append(c.getPassword());
        logger.info(sb.toString());
    }

    @GetMapping("/badFormat")
    void badFormat(Credential c) {
        logger.info(String.format("pwd=%s", c.getPassword()));
    }

    @GetMapping("/badResponse")
    void badResponse(@RequestParam String token, Response resp) {
        resp.getWriter().write(token);
    }

    @GetMapping("/goodConstant")
    void goodConstant() {
        logger.info("ok");
    }

    @GetMapping("/goodNonSensitive")
    void goodNonSensitive(@RequestParam String userName) {
        logger.info(userName);
    }

    static class Credential {
        String getPassword() {
            return null;
        }
    }

    static class Response {
        Writer getWriter() {
            return null;
        }
    }

    static class Writer {
        void write(String s) {
        }
    }
}