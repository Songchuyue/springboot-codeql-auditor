package com.songchuyue.bench.aoplog;

import org.springframework.stereotype.Service;

@Service
public class AopLogService {

    public String processVuln(String secret) {
        return "processed:" + secret;
    }

    public String processSafe(String secret) {
        return "processed";
    }
}
