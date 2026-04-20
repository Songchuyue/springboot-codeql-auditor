import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.stereotype.Controller;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.access.annotation.Secured;

import jakarta.annotation.security.RolesAllowed;

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

@RestController
class ReportController {
  @GetMapping("/admin/audit")
  String badAdminRouteOnly() {
    return "bad";
  }
}

class SecurityReportService {
  void logExport() {
  }
}

@RestController
class AuditController {
  @GetMapping("/admin/logs")
  String badFakeSecurityHelper() {
    new SecurityReportService().logExport();
    return "bad";
  }

  @GetMapping("/admin/panel")
  String badIgnoredHasRole() {
    hasRole("ADMIN");
    return "bad";
  }

  boolean hasRole(String role) {
    return true;
  }
}

@Controller
@RequestMapping("/admin")
class AdminPageController {
  @GetMapping("/dashboard")
  @RolesAllowed({"ADMIN"})
  String goodRolesAllowedDashboard() {
    return "ok";
  }
}

@RestController
@PreAuthorize("hasRole('ADMIN')")
class ProtectedAdminController {
  @GetMapping("/admin/metrics")
  String goodTypeLevelPreAuthorize() {
    return "ok";
  }
}