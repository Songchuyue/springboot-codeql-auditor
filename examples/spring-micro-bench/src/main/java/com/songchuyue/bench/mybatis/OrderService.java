package com.songchuyue.bench.mybatis;

import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class OrderService {
    private final OrderMapper orderMapper;

    public OrderService(OrderMapper orderMapper) {
        this.orderMapper = orderMapper;
    }

    public List<String> listUsersVuln(String orderBy) {
        return orderMapper.listUsersVuln(orderBy);
    }

    public List<String> listUsersSafe(String ignoredInput) {
        // Intentionally ignores user input; query becomes fixed.
        return orderMapper.listUsersSafe();
    }
}
