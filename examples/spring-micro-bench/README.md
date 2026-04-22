# spring-micro-bench

A minimal Spring Boot micro-benchmark used to demonstrate custom CodeQL enhancements for:

- Spring MVC input sources: `@RequestParam`, `@PathVariable`, `@RequestBody`
- MyBatis XML `${}` injection
- `RestClient.create(baseUrl)` and `RestClient.builder().baseUrl(...)`
- `RequestEntity.get("http://{host}/...", host)` template-variable SSRF
- `MultipartFile.getOriginalFilename()` filename taint
- AOP logging via `JoinPoint.getArgs()`

This project is intended for CodeQL database creation and query comparison, not for production deployment.
