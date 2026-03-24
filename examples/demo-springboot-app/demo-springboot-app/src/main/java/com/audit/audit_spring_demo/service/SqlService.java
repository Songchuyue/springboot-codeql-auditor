package com.audit.audit_spring_demo.service;

import com.audit.audit_spring_demo.mapper.UserMapper;
import com.audit.audit_spring_demo.model.User;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class SqlService {
    private final JdbcTemplate jdbcTemplate;
    private final UserMapper userMapper;

    public SqlService(JdbcTemplate jdbcTemplate, UserMapper userMapper) {
        this.jdbcTemplate = jdbcTemplate;
        this.userMapper = userMapper;
    }

    public List<String> searchJdbcUnsafe(String keyword) {
        StringBuilder sql = new StringBuilder("select username from users where username like '%");
        sql.append(keyword);
        sql.append("%'");
        return jdbcTemplate.queryForList(sql.toString(), String.class);
    }

    public List<User> searchMyBatisUnsafe(String orderBy) {
        return userMapper.listOrderBy(orderBy);
    }

    public List<User> searchMyBatisSafe(String username) {
        return userMapper.searchByName(username);
    }
}
