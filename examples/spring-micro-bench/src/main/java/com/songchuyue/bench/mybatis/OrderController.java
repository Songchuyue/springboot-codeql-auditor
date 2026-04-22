package com.songchuyue.bench.mybatis;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/bench/sql/mybatis-dollar")
public class OrderController {
    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    // BENCH: SQL-MYBATIS-DOLLAR-VULN
    @GetMapping("/vuln")
    public List<String> vuln(@RequestParam("orderBy") String orderBy) {
        return orderService.listUsersVuln(orderBy);
    }

    // BENCH: SQL-MYBATIS-DOLLAR-SAFE
    @GetMapping("/safe")
    public List<String> safe(@RequestParam("orderBy") String orderBy) {
        return orderService.listUsersSafe(orderBy);
    }
}
