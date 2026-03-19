import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;
import org.springframework.http.HttpMethod;
import org.springframework.http.RequestEntity;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

@RestController
public class Test {
    private final HttpClient client = HttpClient.newHttpClient();

    @GetMapping("/bad1")
    public void badFullUrl(@RequestParam String url) throws Exception {
        HttpRequest req = HttpRequest.newBuilder(new URI(url))
                .GET()
                .build();
        client.send(req, HttpResponse.BodyHandlers.discarding());
    }

    @GetMapping("/bad2")
    public void badHostOnly(@RequestParam String host) throws Exception {
        URI uri = new URI("http", null, host, -1, "/internal", null, null);
        HttpRequest req = HttpRequest.newBuilder(uri)
                .GET()
                .build();
        client.send(req, HttpResponse.BodyHandlers.discarding());
    }

    @GetMapping("/bad3")
    public void badInterprocedural(@RequestParam String url) throws Exception {
        fetch(url);
    }

    private void fetch(String url) throws Exception {
        HttpRequest req = HttpRequest.newBuilder(new URI(url))
                .GET()
                .build();
        client.send(req, HttpResponse.BodyHandlers.discarding());
    }

    @GetMapping("/good1")
    public void goodFixedAllowlist(@RequestParam String url) throws Exception {
        if (!"https://api.example.com/profile".equals(url)) {
            return;
        }

        HttpRequest req = HttpRequest.newBuilder(new URI(url))
                .GET()
                .build();
        client.send(req, HttpResponse.BodyHandlers.discarding());
    }

    @GetMapping("/good2")
    public void goodRegexAllowlist(@RequestParam String url) throws Exception {
        if (!url.matches("^https://api\\.example\\.com(/[a-zA-Z0-9/_-]*)?$")) {
            return;
        }

        HttpRequest req = HttpRequest.newBuilder(new URI(url))
                .GET()
                .build();
        client.send(req, HttpResponse.BodyHandlers.discarding());
    }

    @GetMapping("/good3")
    public void goodConstant() throws Exception {
        HttpRequest req = HttpRequest.newBuilder(new URI("https://api.example.com/profile"))
                .GET()
                .build();
        client.send(req, HttpResponse.BodyHandlers.discarding());
    }

    @GetMapping("/bad4")
    public String badRestClient(@RequestParam String url) {
        RestClient client = RestClient.create();
        return client.get().uri(url).retrieve().body(String.class);
    }

    @GetMapping("/bad5")
    public String badRestClientBaseUrl(@RequestParam String baseUrl) {
        RestClient client = RestClient.create(baseUrl);
        return client.get().uri("/internal").retrieve().body(String.class);
    }

    @GetMapping("/bad6")
    public String badRestClientTemplate(@RequestParam String host) {
        RestClient client = RestClient.create();
        return client.get().uri("http://{host}/internal", host).retrieve().body(String.class);
    }

    @GetMapping("/bad7")
    public ResponseEntity<String> badRestTemplateExchangeRequestEntityCtor(@RequestParam String url) throws Exception {
        RestTemplate template = new RestTemplate();
        RequestEntity<Void> request = new RequestEntity<>(HttpMethod.GET, new URI(url));
        return template.exchange(request, String.class);
    }

    @GetMapping("/bad8")
    public ResponseEntity<String> badRestTemplateExchangeRequestEntityTemplate(@RequestParam String host) {
        RestTemplate template = new RestTemplate();
        RequestEntity<Void> request = RequestEntity.get("http://{host}/internal", host).build();
        return template.exchange(request, String.class);
    }

    @GetMapping("/good4")
    public ResponseEntity<String> goodRestTemplateExchangeAllowlist(@RequestParam String url) throws Exception {
        if (!"https://api.example.com/profile".equals(url)) {
            return null;
        }
        RestTemplate template = new RestTemplate();
        RequestEntity<Void> request = new RequestEntity<>(HttpMethod.GET, new URI(url));
        return template.exchange(request, String.class);
    }
}