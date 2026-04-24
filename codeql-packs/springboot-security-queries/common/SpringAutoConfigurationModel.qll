/**
 * common/SpringAutoConfigurationModel.qll
 *
 * 最小 Spring Boot Auto-Configuration 语义层：
 *
 * 支持：
 * 1. @SpringBootApplication / @EnableAutoConfiguration 启用自动配置；
 * 2. @AutoConfiguration 类型识别；
 * 3. 注解级 exclude / excludeName；
 * 4. 低成本 @ConditionalOnClass(name=...) / @ConditionalOnMissingClass(name=...) 判断。
 *
 * 不支持：
 * 1. 直接解析依赖 jar 中的 AutoConfiguration.imports；
 * 2. 直接解析 Spring Boot 2.x spring.factories；
 * 3. Maven / Gradle starter 依赖图；
 * 4. application.yml / application.properties / profile / 环境变量；
 * 5. @ConditionalOnProperty / @Profile / @ConditionalOnBean / @ConditionalOnMissingBean 的精确求值；
 * 6. 自动配置顺序 before/after。
 *
 * 目的：
 * 不是复现 Spring Boot 容器，而是让源码中可见的自动配置类参与 Bean 候选，
 * 用于降低因漏建模导致的 DI / guard / sink 识别漏报。
 */

import java

private predicate hasQualifiedAnnotation(Annotatable a, string pkg, string name) {
  exists(Annotation ann |
    ann = a.getAnAnnotation() and
    ann.getType().hasQualifiedName(pkg, name)
  )
}

/** @SpringBootApplication 本身包含 EnableAutoConfiguration 语义。 */
predicate isSpringBootApplicationType(RefType t) {
  hasQualifiedAnnotation(
    t,
    "org.springframework.boot.autoconfigure",
    "SpringBootApplication"
  )
}

/** 显式 @EnableAutoConfiguration。 */
predicate isEnableAutoConfigurationType(RefType t) {
  hasQualifiedAnnotation(
    t,
    "org.springframework.boot.autoconfigure",
    "EnableAutoConfiguration"
  )
}

/** 当前工程是否启用了 Spring Boot 自动配置。 */
predicate hasSpringBootAutoConfigurationEnabled() {
  exists(RefType t |
    isSpringBootApplicationType(t) or
    isEnableAutoConfigurationType(t)
  )
}

/** Spring Boot 2.7+ / 3.x 推荐的自动配置类注解。 */
predicate isDeclaredAutoConfigurationType(RefType t) {
  hasQualifiedAnnotation(
    t,
    "org.springframework.boot.autoconfigure",
    "AutoConfiguration"
  )
}

/**
 * 兼容旧工程里的命名习惯。
 *
 * 注意：
 * 这是启发式规则，精度低于 @AutoConfiguration。
 * 如果你担心误报，可以先删掉这个 predicate 的第二个分支。
 */
predicate isLikelyLegacyAutoConfigurationType(RefType t) {
  hasQualifiedAnnotation(
    t,
    "org.springframework.context.annotation",
    "Configuration"
  ) and
  t.getName().matches("%AutoConfiguration") and
  (
    t.getPackage().getName().matches("%autoconfigure%") or
    t.getPackage().getName().matches("%autoconfiguration%")
  )
}

/** 候选自动配置类。 */
predicate isAutoConfigurationCandidateType(RefType t) {
  isDeclaredAutoConfigurationType(t)
  or
  isLikelyLegacyAutoConfigurationType(t)
}

/** @SpringBootApplication(exclude = XxxAutoConfiguration.class) */
private predicate getAutoConfigurationExcludeType(RefType excluded) {
  exists(RefType config, Annotation ann |
    (
      isSpringBootApplicationType(config) or
      isEnableAutoConfigurationType(config)
    ) and
    ann = config.getAnAnnotation() and
    (
      ann.getType().hasQualifiedName(
        "org.springframework.boot.autoconfigure",
        "SpringBootApplication"
      )
      or
      ann.getType().hasQualifiedName(
        "org.springframework.boot.autoconfigure",
        "EnableAutoConfiguration"
      )
    ) and
    (
      excluded = ann.getTypeValue("exclude") or
      excluded = ann.getATypeArrayValue("exclude")
    )
  )
}

/** @SpringBootApplication(excludeName = "xxx.XxxAutoConfiguration") */
private predicate getAutoConfigurationExcludeName(string excludedName) {
  exists(RefType config, Annotation ann |
    (
      isSpringBootApplicationType(config) or
      isEnableAutoConfigurationType(config)
    ) and
    ann = config.getAnAnnotation() and
    (
      ann.getType().hasQualifiedName(
        "org.springframework.boot.autoconfigure",
        "SpringBootApplication"
      )
      or
      ann.getType().hasQualifiedName(
        "org.springframework.boot.autoconfigure",
        "EnableAutoConfiguration"
      )
    ) and
    (
      excludedName = ann.getStringValue("excludeName") or
      excludedName = ann.getAStringArrayValue("excludeName")
    ) and
    excludedName != ""
  )
}

predicate isExcludedAutoConfigurationType(RefType t) {
  getAutoConfigurationExcludeType(t)
  or
  exists(string excludedName |
    getAutoConfigurationExcludeName(excludedName) and
    excludedName = t.getQualifiedName()
  )
}

/** 判断数据库中是否能看到某个全限定类名。 */
private predicate classNamedExists(string qualifiedName) {
  exists(RefType t |
    t.getQualifiedName() = qualifiedName
  )
}

/** 读取 @ConditionalOnClass(name = "...") / @ConditionalOnMissingClass(name = "...") */
private predicate getConditionClassName(Annotation ann, string className) {
  (
    className = ann.getStringValue("name") or
    className = ann.getAStringArrayValue("name")
  ) and
  className != ""
}

/**
 * 低成本 classpath 条件过滤。
 *
 * 只处理 name = "fully.qualified.ClassName"。
 * 不处理 value = SomeClass.class，因为在源码层面如果类不存在通常无法编译，
 * 对依赖 jar 自动配置源码也未必在 CodeQL DB 中可见。
 */
private predicate hasUnsatisfiedClassCondition(Annotatable a) {
  exists(Annotation ann, string className |
    ann = a.getAnAnnotation() and
    ann.getType().hasQualifiedName(
      "org.springframework.boot.autoconfigure.condition",
      "ConditionalOnClass"
    ) and
    getConditionClassName(ann, className) and
    not classNamedExists(className)
  )
  or
  exists(Annotation ann, string className |
    ann = a.getAnAnnotation() and
    ann.getType().hasQualifiedName(
      "org.springframework.boot.autoconfigure.condition",
      "ConditionalOnMissingClass"
    ) and
    getConditionClassName(ann, className) and
    classNamedExists(className)
  )
}

/**
 * 运行时条件：只识别，不用于默认裁剪。
 *
 * 原因：
 * @ConditionalOnProperty / @Profile / @ConditionalOnExpression 依赖运行时环境。
 * 静态分析如果强行裁剪，容易漏报。
 */
predicate hasRuntimeOnlyCondition(Annotatable a) {
  exists(Annotation ann |
    ann = a.getAnAnnotation() and
    (
      ann.getType().hasQualifiedName(
        "org.springframework.boot.autoconfigure.condition",
        "ConditionalOnProperty"
      )
      or
      ann.getType().hasQualifiedName(
        "org.springframework.context.annotation",
        "Profile"
      )
      or
      ann.getType().hasQualifiedName(
        "org.springframework.boot.autoconfigure.condition",
        "ConditionalOnExpression"
      )
      or
      ann.getType().hasQualifiedName(
        "org.springframework.boot.autoconfigure.condition",
        "ConditionalOnWebApplication"
      )
      or
      ann.getType().hasQualifiedName(
        "org.springframework.boot.autoconfigure.condition",
        "ConditionalOnNotWebApplication"
      )
    )
  )
}

/**
 * 最终认为“可能生效”的自动配置类。
 *
 * 这是 recall-first 策略：
 * - 能确定被 exclude 或 class 条件不满足时，排除；
 * - 环境条件不确定时，不排除。
 */
predicate isActiveAutoConfigurationType(RefType t) {
  hasSpringBootAutoConfigurationEnabled() and
  isAutoConfigurationCandidateType(t) and
  not isExcludedAutoConfigurationType(t) and
  not hasUnsatisfiedClassCondition(t)
}

/**
 * 自动配置类的嵌套 @Configuration。
 *
 * 常见写法：
 *
 * @AutoConfiguration
 * class XxxAutoConfiguration {
 *   @Configuration
 *   @ConditionalOnClass(...)
 *   static class NestedConfiguration {
 *     @Bean ...
 *   }
 * }
 */
predicate isNestedConfigurationInActiveAutoConfiguration(RefType nested) {
  exists(RefType outer |
    nested.getEnclosingType() = outer and
    isActiveAutoConfigurationType(outer) and
    hasQualifiedAnnotation(
      nested,
      "org.springframework.context.annotation",
      "Configuration"
    ) and
    not hasUnsatisfiedClassCondition(nested)
  )
}