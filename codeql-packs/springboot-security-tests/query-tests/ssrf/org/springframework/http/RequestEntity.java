package org.springframework.http;

import java.net.URI;

public class RequestEntity<T> {
    public RequestEntity(HttpMethod method, URI url) {
    }

    public RequestEntity(T body, HttpMethod method, URI url) {
    }

    public static HeadersBuilder get(URI url) {
        return new HeadersBuilder();
    }

    public static HeadersBuilder get(String uriTemplate, Object... uriVariables) {
        return new HeadersBuilder();
    }

    public static HeadersBuilder method(HttpMethod method, URI url) {
        return new HeadersBuilder();
    }

    public static HeadersBuilder method(HttpMethod method, String uriTemplate, Object... uriVariables) {
        return new HeadersBuilder();
    }

    public static class HeadersBuilder {
        public <X> RequestEntity<X> build() {
            return new RequestEntity<X>(HttpMethod.GET, URI.create("http://example.com"));
        }
    }

    public static class BodyBuilder extends HeadersBuilder {
    }
}