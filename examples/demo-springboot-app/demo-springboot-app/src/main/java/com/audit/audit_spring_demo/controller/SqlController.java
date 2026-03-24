package com.audit.audit_spring_demo.controller;

import com.audit.audit_spring_demo.model.User;
import com.audit.audit_spring_demo.service.SqlService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class SqlController {
    private final SqlService sqlService;

    public SqlController(SqlService sqlService) {
        this.sqlService = sqlService;
    }

    @GetMapping("/sql/jdbcUnsafe")
    public List<String> jdbcUnsafe(@RequestParam String keyword) {
        return sqlService.searchJdbcUnsafe(keyword);
    }

    @GetMapping("/sql/mybatisUnsafe")
    public List<User> myBatisUnsafe(@RequestParam String orderBy) {
        return sqlService.searchMyBatisUnsafe(orderBy);
    }

    @GetMapping("/sql/mybatisSafe")
    public List<User> myBatisSafe(@RequestParam String username) {
        return sqlService.searchMyBatisSafe(username);
    }
}
