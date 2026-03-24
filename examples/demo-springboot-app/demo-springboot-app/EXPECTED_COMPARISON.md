# Expected comparison against official queries

这不是实测结果，而是**根据你当前 main 分支查询代码反推的预期对比矩阵**。真正论文里要以你本地跑出来的 SARIF 为准。

## 1. 高把握的“你的查询应有提升”的点

### SQL 注入
- `/sql/mybatisUnsafe`
  - 你的查询：**应命中**
  - 原因：你当前默认套件额外启用了 `MyBatisXmlDollarPlaceholderSqlInjection.ql`，专门识别 MyBatis XML 中 `${...}` 占位符与 mapper 参数之间的数据流。

### SSRF
- `/fetch/restClientBaseUrlUnsafe`
- `/fetch/restClientUriVariableUnsafe`
- `/fetch/requestEntityBuilderUnsafe`
- `/fetch/restClientBuilderBaseUrlUnsafe`
  - 你的查询：**应命中**
  - 原因：`SsrfLib.qll` 明确补了 `RestClient.create(baseUrl)`、`RestClient.builder().baseUrl(...)`、`uri(..., uriVariables...)`、`RequestEntity.get("http://{host}/...", host)` 等 sink。

### 命令注入
- `/cmd/processBuilderListUnsafe`
- `/cmd/processBuilderArraysListUnsafe`
  - 你的查询：**应命中**
  - 原因：`CommandInjectionLib.qll` 专门补了 `ProcessBuilder(List)` / `pb.command(List)` 且 list 形如 `["sh", "-c", tainted]` 的 sink。

### 日志注入
- `/log/wrapperUnsafe`
- `/log/aopUnsafe`
  - 你的查询：**应命中**
  - 原因：`LogInjectionLib.qll` 补了项目自定义 logger wrapper sink，以及 target call → advice 参数 / `JoinPoint.getArgs()` → 日志表达式的传播。

### XSS
- `/xss/builderUnsafe`
- `/xss/formatUnsafe`
  - 你的查询：**更可能命中**
  - 原因：`XssLib.qll` 明确补了 `StringBuilder.append`、`builder.toString()`、`String.format(...)` 的传播。

### 路径穿越误报收敛
- `/file/readSafe`
  - 你的查询：**更可能不报或更容易压下误报**
  - 原因：`PathTraversalLib.qll` 明确认 `isSafeRelativePath`、`sanitizeFilename` 这类命名式 sanitizer / guard。

## 2. 基线样例：官方与自定义都应命中
- `/file/readUnsafe`
- `/sql/jdbcUnsafe`
- `/fetch/openStreamUnsafe`
- `/cmd/runtimeUnsafe`
- `/xss/directUnsafe`
- `POST /deserialize/base64Unsafe`

## 3. 负例
- `/sql/mybatisSafe`
- `/fetch/onlyAllowExampleCom`
- `/cmd/onlyAllowDate`
- `/log/wrapperSafe`
- `/xss/safe`

## 4. 论文里怎么写才严谨

不要写“官方一定检不出来”。

应该写成：

- “根据当前自定义查询代码的 sink / flow / sanitizer 建模，这些样例被设计为验证自定义增强点。”
- “最终提升结论以本地实测 SARIF 与人工复核为准。”
