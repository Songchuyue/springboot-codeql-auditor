# demo-springboot-app

这是一个**专门为对比官方 CodeQL 查询与当前自定义查询包**而写的 SpringBoot 靶场，不是普通 CRUD 示例。

## 设计原则

1. 每个端点尽量只验证一个建模点。
2. 同时保留“官方也应命中”的基线样例，避免项目只证明自定义规则。
3. 单独放入“你当前仓库已显式增强”的场景：
   - MyBatis XML `${...}` SQL 注入
   - Spring `RestClient` / `RequestEntity` SSRF
   - `ProcessBuilder(List.of("sh", "-c", cmd))` 命令执行
   - 自定义日志包装器与 AOP advice 日志链
   - 命名式路径清洗/校验函数带来的误报收敛
   - `StringBuilder` / `String.format` 到 XSS sink 的传播

## 端点对照表

| 类别 | 端点 | 目的 |
|---|---|---|
| 路径穿越 | `/file/readUnsafe?name=...` | 官方与自定义都应命中 |
| 路径穿越 | `/file/readSafe?name=...` | 用 `isSafeRelativePath` + `sanitizeFilename` 验证自定义 sanitizer |
| SQL 注入 | `/sql/jdbcUnsafe?keyword=...` | 官方与自定义都应命中 |
| SQL 注入 | `/sql/mybatisUnsafe?orderBy=...` | 验证 MyBatis XML `${...}` 专项查询 |
| SQL 注入 | `/sql/mybatisSafe?username=...` | 负例，`#{...}` 参数绑定 |
| SSRF | `/fetch/openStreamUnsafe?url=...` | 官方与自定义都应命中 |
| SSRF | `/fetch/restClientBaseUrlUnsafe?baseUrl=...` | 验证 `RestClient.create(baseUrl)` sink |
| SSRF | `/fetch/restClientUriVariableUnsafe?host=...` | 验证 `uri("http://{host}/...", host)` |
| SSRF | `/fetch/requestEntityBuilderUnsafe?host=...` | 验证 `RequestEntity.get("http://{host}/...", host)` |
| SSRF | `/fetch/restClientBuilderBaseUrlUnsafe?baseUrl=...` | 验证 `RestClient.builder().baseUrl(...)` |
| SSRF | `/fetch/onlyAllowExampleCom?url=...` | 负例，固定 allowlist |
| 命令注入 | `/cmd/runtimeUnsafe?cmd=...` | 官方与自定义都应命中 |
| 命令注入 | `/cmd/processBuilderListUnsafe?cmd=...` | 验证 `ProcessBuilder(List)` 壳启动场景 |
| 命令注入 | `/cmd/processBuilderArraysListUnsafe?cmd=...` | 验证 `Arrays.asList(...)` 变体 |
| 命令注入 | `/cmd/onlyAllowDate?action=...` | 负例，固定 allowlist |
| 日志注入 | `/log/wrapperUnsafe?name=...` | 验证自定义 `AuditLogger` wrapper sink |
| 日志注入 | `/log/wrapperSafe?name=...` | 负例，`hasNoLineBreaks` + `removeLineBreaks` |
| 日志注入 | `/log/aopUnsafe?payload=...` | 验证 AOP advice 中 `JoinPoint.getArgs()` 日志链 |
| XSS | `/xss/directUnsafe?q=...` | 官方与自定义都应命中 |
| XSS | `/xss/builderUnsafe?q=...` | 验证 `StringBuilder` 传播 |
| XSS | `/xss/formatUnsafe?q=...` | 验证 `String.format` 传播 |
| XSS | `/xss/safe?q=...` | 负例，`HtmlUtils.htmlEscape(...)` |
| 反序列化 | `POST /deserialize/base64Unsafe` | 官方与自定义都应命中 |

## 放到你的仓库里的建议位置

直接覆盖：

```text
springboot-codeql-auditor/examples/demo-springboot-app/
```

因为你当前主分支里这个目录还是空的，只有 `.gitkeep`。

## 建库与分析

先在你的仓库根目录执行：

```powershell
.\scripts\create-db.ps1 -ProjectPath .\examples\demo-springboot-app
.\scripts\analyze.ps1 -ProjectPath .\examples\demo-springboot-app
```

然后再单独对同一个数据库跑官方查询，和自定义查询结果做对比。

## 对比建议

不要只比“总告警数”，而要逐端点比：

- 是否命中
- 是否有路径
- 是否有误报
- 是否能解释成“为什么这是你的增强点”

更合理的统计单位是：**按端点/样例统计 TP、FP、FN**。
