package javax.servlet.http;

import java.io.PrintWriter;

public interface HttpServletResponse {
    PrintWriter getWriter();
    void setContentType(String type);
}