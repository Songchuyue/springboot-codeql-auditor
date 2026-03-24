package com.audit.audit_spring_demo.service;

import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.io.ObjectInputStream;
import java.util.Base64;

@Service
public class DeserializeService {
    public Object deserializeBase64Unsafe(String payload) throws Exception {
        byte[] bytes = Base64.getDecoder().decode(payload);
        try (ObjectInputStream in = new ObjectInputStream(new ByteArrayInputStream(bytes))) {
            return in.readObject();
        }
    }
}
