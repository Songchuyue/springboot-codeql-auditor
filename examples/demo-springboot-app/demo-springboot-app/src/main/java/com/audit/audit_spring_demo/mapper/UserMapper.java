package com.audit.audit_spring_demo.mapper;

import com.audit.audit_spring_demo.model.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface UserMapper {
    List<User> searchByName(@Param("username") String username);

    List<User> listOrderBy(@Param("orderBy") String orderBy);
}
