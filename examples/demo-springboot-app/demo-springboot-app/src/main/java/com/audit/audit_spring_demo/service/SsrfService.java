package com.audit.audit_spring_demo.service;

import org.springframework.http.RequestEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.URL;
import java.nio.charset.StandardCharsets;

@Service
public class SsrfService {
    public String openStreamUnsafe(String url) throws Exception {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(new URL(url).openStream(), StandardCharsets.UTF_8))) {
            return reader.readLine();
        }
    }

    public String restClientBaseUrlUnsafe(String baseUrl) {
        RestClient client = RestClient.create(baseUrl);
        return client.get().uri("/internal").retrieve().body(String.class);
    }

    public String restClientUriVariableUnsafe(String host) {
        RestClient client = RestClient.create();
        return client.get()
                .uri("http://{host}/internal", host)
                .retrieve()
                .body(String.class);
    }

    public RequestEntity<Void> requestEntityBuilderUnsafe(String host) {
        return RequestEntity.get("http://{host}/internal", host).build();
    }

    public String onlyAllowExampleCom(String url) {
        if (!"https://example.com/api/health".equals(url)) {
            throw new IllegalArgumentException("blocked");
        }
        RestClient client = RestClient.create(url);
        return client.get().retrieve().body(String.class);
    }

    public String restClientBuilderBaseUrlUnsafe(URI baseUri) {
        RestClient client = RestClient.builder().baseUrl(baseUri.toString()).build();
        return client.get().uri("/status").retrieve().body(String.class);
    }
}
