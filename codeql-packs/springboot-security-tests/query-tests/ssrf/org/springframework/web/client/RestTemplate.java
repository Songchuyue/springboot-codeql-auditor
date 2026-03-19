package org.springframework.web.client;

import org.springframework.http.RequestEntity;
import org.springframework.http.ResponseEntity;

public class RestTemplate {
    public <T> ResponseEntity<T> exchange(RequestEntity<?> requestEntity, Class<T> responseType) {
        return new ResponseEntity<T>();
    }
}