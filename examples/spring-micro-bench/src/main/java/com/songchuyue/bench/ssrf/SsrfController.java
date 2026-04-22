package com.songchuyue.bench.ssrf;

import com.songchuyue.bench.common.ReqDto;
import org.springframework.http.RequestEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestTemplate;

@RestController
@RequestMapping("/bench/ssrf")
public class SsrfController {

    // BENCH: SSRF-RESTCLIENT-CREATE-VULN
    @GetMapping("/restclient-create/vuln")
    public String restClientCreateVuln(@RequestParam("baseUrl") String baseUrl) {
        RestClient client = RestClient.create(baseUrl);
        return client.get().uri("/internal").retrieve().body(String.class);
    }

    // BENCH: SSRF-RESTCLIENT-CREATE-SAFE
    @GetMapping("/restclient-create/safe")
    public String restClientCreateSafe(@RequestParam("baseUrl") String ignored) {
        RestClient client = RestClient.create("http://example.com");
        return client.get().uri("/internal").retrieve().body(String.class);
    }

    // BENCH: SSRF-RESTCLIENT-BUILDER-VULN
    @GetMapping("/restclient-builder/vuln")
    public String restClientBuilderVuln(@RequestParam("baseUrl") String baseUrl) {
        RestClient client = RestClient.builder().baseUrl(baseUrl).build();
        return client.get().uri("/internal").retrieve().body(String.class);
    }

    // BENCH: SSRF-RESTCLIENT-BUILDER-SAFE
    @GetMapping("/restclient-builder/safe")
    public String restClientBuilderSafe(@RequestParam("baseUrl") String ignored) {
        RestClient client = RestClient.builder().baseUrl("http://example.com").build();
        return client.get().uri("/internal").retrieve().body(String.class);
    }

    // BENCH: SSRF-REQUESTENTITY-TEMPLATE-VULN
    @GetMapping("/request-entity-template/vuln")
    public String requestEntityTemplateVuln(@RequestParam("host") String host) {
        RestTemplate rt = new RestTemplate();
        RequestEntity<Void> req = RequestEntity.get("http://{host}/internal", host).build();
        return rt.exchange(req, String.class).getBody();
    }

    // BENCH: SSRF-REQUESTENTITY-TEMPLATE-SAFE
    @GetMapping("/request-entity-template/safe")
    public String requestEntityTemplateSafe(@RequestParam("host") String ignored) {
        RestTemplate rt = new RestTemplate();
        RequestEntity<Void> req = RequestEntity.get("http://example.com/internal").build();
        return rt.exchange(req, String.class).getBody();
    }

    // BENCH: SSRF-REQUESTBODY-HOST-VULN
    @PostMapping("/request-body-host/vuln")
    public String requestBodyHostVuln(@RequestBody ReqDto dto) {
        RestTemplate rt = new RestTemplate();
        RequestEntity<Void> req = RequestEntity.get("http://{host}/internal", dto.getHost()).build();
        return rt.exchange(req, String.class).getBody();
    }

    // BENCH: SSRF-REQUESTBODY-HOST-SAFE
    @PostMapping("/request-body-host/safe")
    public String requestBodyHostSafe(@RequestBody ReqDto dto) {
        RestTemplate rt = new RestTemplate();
        RequestEntity<Void> req = RequestEntity.get("http://example.com/internal").build();
        return rt.exchange(req, String.class).getBody();
    }
}
