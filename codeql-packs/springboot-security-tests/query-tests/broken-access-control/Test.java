import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.access.annotation.Secured;

@RestController
class AdminController {

    @GetMapping("/admin/users")
    String badListUsers() {
        return "bad";
    }

    @PostMapping("/admin/delete")
    @PreAuthorize("hasRole('ADMIN')")
    void goodDeleteUser() {
    }

    @GetMapping("/admin/export")
    String goodExportWithGuard() {
        checkPermission("admin:export");
        return "ok";
    }

    void checkPermission(String perm) {
    }
}

@RestController
class UserController {

    @GetMapping("/profile")
    String goodProfile() {
        return "ok";
    }

    @GetMapping("/admin/role")
    @Secured("ROLE_ADMIN")
    String goodSecuredAdminRole() {
        return "ok";
    }
}