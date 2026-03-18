import javax.servlet.http.HttpServletResponse;
import org.owasp.encoder.Encode;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.util.HtmlUtils;

@RestController
class Test {
    private final ViewService viewService = new ViewService();

    @GetMapping("/badPrint")
    void badPrint(@RequestParam String name, HttpServletResponse response) throws Exception {
        response.setContentType("text/html");
        response.getWriter().print("<h1>Hello " + name + "</h1>");
    }

    @GetMapping("/badBuilder")
    void badBuilder(@RequestParam String name, HttpServletResponse response) throws Exception {
        response.setContentType("text/html");
        StringBuilder sb = new StringBuilder("<div>");
        sb.append(name);
        sb.append("</div>");
        response.getWriter().println(sb.toString());
    }

    @GetMapping("/badFormat")
    void badFormat(@RequestParam String name, HttpServletResponse response) throws Exception {
        response.setContentType("text/html");
        String html = String.format("<span>%s</span>", name);
        response.getWriter().write(html);
    }

    @GetMapping("/badCrossLayer")
    void badCrossLayer(@RequestParam String name, HttpServletResponse response) throws Exception {
        response.setContentType("text/html");
        response.getWriter().print(viewService.render(name));
    }

    @GetMapping("/goodSpringEscape")
    void goodSpringEscape(@RequestParam String name, HttpServletResponse response) throws Exception {
        response.setContentType("text/html");
        response.getWriter().print("<h1>Hello " + HtmlUtils.htmlEscape(name) + "</h1>");
    }

    @GetMapping("/goodOwaspEncode")
    void goodOwaspEncode(@RequestParam String name, HttpServletResponse response) throws Exception {
        response.setContentType("text/html");
        String safe = Encode.forHtml(name);
        response.getWriter().print("<div>" + safe + "</div>");
    }

    @GetMapping("/goodConstant")
    void goodConstant(HttpServletResponse response) throws Exception {
        response.setContentType("text/html");
        response.getWriter().print("<p>fixed</p>");
    }

    static class ViewService {
        String render(String name) {
            return "<section>" + name + "</section>";
        }
    }
}