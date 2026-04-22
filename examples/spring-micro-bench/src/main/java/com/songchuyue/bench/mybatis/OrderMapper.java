package com.songchuyue.bench.mybatis;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface OrderMapper {
    List<String> listUsersVuln(@Param("orderBy") String orderBy);

    List<String> listUsersSafe();
}
