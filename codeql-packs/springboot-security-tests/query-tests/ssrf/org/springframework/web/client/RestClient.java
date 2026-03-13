package org.springframework.web.client;

import java.net.URI;
import java.util.Map;

public class RestClient {

    public static RestClient create() {
        return new RestClient();
    }

    public static RestClient create(String baseUrl) {
        return new RestClient();
    }

    public static RestClient create(URI baseUrl) {
        return new RestClient();
    }

    public RequestHeadersUriSpec get() {
        return new RequestHeadersUriSpec();
    }

    public RequestHeadersUriSpec post() {
        return new RequestHeadersUriSpec();
    }

    public RequestHeadersUriSpec put() {
        return new RequestHeadersUriSpec();
    }

    public RequestHeadersUriSpec delete() {
        return new RequestHeadersUriSpec();
    }

    public static class RequestHeadersUriSpec {

        public RequestHeadersSpec uri(String uri) {
            return new RequestHeadersSpec();
        }

        public RequestHeadersSpec uri(URI uri) {
            return new RequestHeadersSpec();
        }

        public RequestHeadersSpec uri(String uriTemplate, Object... uriVariables) {
            return new RequestHeadersSpec();
        }

        public RequestHeadersSpec uri(String uriTemplate, Map<String, ?> uriVariables) {
            return new RequestHeadersSpec();
        }
    }

    public static class RequestHeadersSpec {

        public ResponseSpec retrieve() {
            return new ResponseSpec();
        }
    }

    public static class ResponseSpec {

        public <T> T body(Class<T> responseType) {
            return null;
        }
    }
}