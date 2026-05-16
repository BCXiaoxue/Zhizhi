-- 智知（ZhiZhi）数据库初始化脚本
-- MySQL 8.0+，执行前请先创建数据库

CREATE DATABASE IF NOT EXISTS zhizhi DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE zhizhi;

-- 用户表
CREATE TABLE IF NOT EXISTS `user` (
    `id`         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `username`   VARCHAR(50)  NOT NULL COMMENT '用户名',
    `password`   VARCHAR(255) NOT NULL COMMENT '密码（BCrypt加密）',
    `email`      VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
    `avatar`     VARCHAR(255) DEFAULT NULL COMMENT '头像URL',
    `role`       TINYINT      NOT NULL DEFAULT 0 COMMENT '角色 0:普通用户 1:管理员',
    `deleted`    TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除 0:正常 1:已删除',
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 知识分类表（树形结构）
CREATE TABLE IF NOT EXISTS `category` (
    `id`         BIGINT      NOT NULL AUTO_INCREMENT COMMENT '分类ID',
    `name`       VARCHAR(100) NOT NULL COMMENT '分类名称',
    `parent_id`  BIGINT      NOT NULL DEFAULT 0 COMMENT '父分类ID，0表示根节点',
    `user_id`    BIGINT      NOT NULL COMMENT '所属用户ID',
    `sort`       INT         NOT NULL DEFAULT 0 COMMENT '排序权重',
    `deleted`    TINYINT     NOT NULL DEFAULT 0,
    `created_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识分类表';

-- 知识条目表
CREATE TABLE IF NOT EXISTS `knowledge` (
    `id`            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '知识ID',
    `title`         VARCHAR(255) NOT NULL COMMENT '标题',
    `content`       LONGTEXT     DEFAULT NULL COMMENT '正文（Markdown格式）',
    `summary`       VARCHAR(500) DEFAULT NULL COMMENT 'AI生成摘要',
    `category_id`   BIGINT       DEFAULT NULL COMMENT '分类ID',
    `user_id`       BIGINT       NOT NULL COMMENT '所属用户ID',
    `view_count`    INT          NOT NULL DEFAULT 0 COMMENT '浏览次数',
    `is_vectorized` TINYINT      NOT NULL DEFAULT 0 COMMENT '是否已向量化 0:否 1:是',
    `deleted`       TINYINT      NOT NULL DEFAULT 0,
    `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_category_id` (`category_id`),
    FULLTEXT KEY `ft_title_content` (`title`, `content`) WITH PARSER ngram
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识条目表';

-- 标签表
CREATE TABLE IF NOT EXISTS `tag` (
    `id`         BIGINT      NOT NULL AUTO_INCREMENT COMMENT '标签ID',
    `name`       VARCHAR(50) NOT NULL COMMENT '标签名称',
    `user_id`    BIGINT      NOT NULL COMMENT '所属用户ID',
    `deleted`    TINYINT     NOT NULL DEFAULT 0,
    `created_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_tag` (`user_id`, `name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='标签表';

-- 知识-标签关联表
CREATE TABLE IF NOT EXISTS `knowledge_tag` (
    `knowledge_id` BIGINT NOT NULL COMMENT '知识ID',
    `tag_id`       BIGINT NOT NULL COMMENT '标签ID',
    PRIMARY KEY (`knowledge_id`, `tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识-标签关联表';

-- 对话会话表
CREATE TABLE IF NOT EXISTS `chat_session` (
    `id`         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '会话ID',
    `user_id`    BIGINT       NOT NULL COMMENT '用户ID',
    `title`      VARCHAR(255) DEFAULT '新对话' COMMENT '会话标题',
    `deleted`    TINYINT      NOT NULL DEFAULT 0,
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='对话会话表';

-- 对话消息表
CREATE TABLE IF NOT EXISTS `chat_message` (
    `id`         BIGINT    NOT NULL AUTO_INCREMENT COMMENT '消息ID',
    `session_id` BIGINT    NOT NULL COMMENT '会话ID',
    `role`       VARCHAR(10) NOT NULL COMMENT '角色 user/assistant',
    `content`    TEXT      NOT NULL COMMENT '消息内容',
    `sources`    JSON      DEFAULT NULL COMMENT '引用的知识条目ID列表',
    `created_at` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_session_id` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='对话消息表';

-- 初始管理员账号（密码：admin123，BCrypt加密）
INSERT IGNORE INTO `user` (`username`, `password`, `email`, `role`) VALUES
('admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBpwTTyGTes9su', 'admin@zhizhi.com', 1);

-- ================================================================
-- 示例数据（供演示和开发调试使用）
-- admin 账号 id=1，密码 admin123
-- ================================================================

-- 普通测试用户（密码：test123）
INSERT IGNORE INTO `user` (`username`, `password`, `email`, `role`) VALUES
('testuser', '$2a$10$7EqJtq98hPqEX7fNZaFWoOe1g7cFmCQEzVsFAp0H7mGRyINqX3V2a', 'test@zhizhi.com', 0);

-- ================================================================
-- 知识分类（admin 的分类，user_id=1）
-- ================================================================
INSERT INTO `category` (`id`, `name`, `parent_id`, `user_id`, `sort`) VALUES
(1,  'Java 开发',      0, 1, 1),
(2,  'Spring 生态',    1, 1, 1),
(3,  'Spring Boot',   2, 1, 1),
(4,  'Spring AI',     2, 1, 2),
(5,  '前端开发',       0, 1, 2),
(6,  'Vue 3',         5, 1, 1),
(7,  '数据库',         0, 1, 3),
(8,  'MySQL',         7, 1, 1),
(9,  'Redis',         7, 1, 2),
(10, '人工智能',       0, 1, 4),
(11, 'RAG 技术',      10, 1, 1),
(12, '大语言模型',     10, 1, 2);

-- ================================================================
-- 标签
-- ================================================================
INSERT INTO `tag` (`id`, `name`, `user_id`) VALUES
(1,  'Java',        1),
(2,  'Spring Boot', 1),
(3,  'Spring AI',   1),
(4,  'Vue3',        1),
(5,  'MySQL',       1),
(6,  'Redis',       1),
(7,  'RAG',         1),
(8,  'LLM',         1),
(9,  'DeepSeek',    1),
(10, 'JWT',         1),
(11, 'MyBatis',     1),
(12, '后端开发',     1),
(13, '前端开发',     1),
(14, '向量数据库',   1);

-- ================================================================
-- 知识条目
-- ================================================================
INSERT INTO `knowledge` (`id`, `title`, `content`, `summary`, `category_id`, `user_id`, `is_vectorized`) VALUES

(1, 'Spring Boot 3 快速入门',
'# Spring Boot 3 快速入门

## 什么是 Spring Boot？

Spring Boot 是 Spring 框架的脚手架，通过**自动配置**和**约定优于配置**的理念，让开发者能够快速搭建生产级 Spring 应用，无需编写大量样板配置。

## 创建项目

推荐使用 [Spring Initializr](https://start.spring.io) 在线生成：

1. 选择 Maven 项目
2. Spring Boot 版本选 3.x
3. 添加依赖：Spring Web、Spring Data JPA、MySQL Driver

## 核心注解

| 注解 | 说明 |
|------|------|
| `@SpringBootApplication` | 入口类注解，等价于 @Configuration + @ComponentScan + @EnableAutoConfiguration |
| `@RestController` | Controller + ResponseBody 的组合 |
| `@GetMapping` | GET 请求映射 |
| `@Service` | 标记业务层组件 |
| `@Repository` | 标记数据访问层组件 |

## application.yml 配置

```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/demo
    username: root
    password: 123456
```

## 自动配置原理

Spring Boot 启动时扫描 `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` 文件，按条件注册 Bean，这就是零配置的秘密。',
'Spring Boot 3 的快速入门指南，涵盖项目创建、核心注解和 application.yml 配置，以及自动配置原理简介。', 3, 1, 0),

(2, 'MyBatis-Plus 常用功能速查',
'# MyBatis-Plus 常用功能速查

## 基础 CRUD

继承 `BaseMapper<T>` 即可获得内置的增删改查方法：

```java
// 新增
userMapper.insert(user);
// 按 ID 查询
User user = userMapper.selectById(1L);
// 更新
userMapper.updateById(user);
// 删除（逻辑删除）
userMapper.deleteById(1L);
```

## 条件构造器

```java
// LambdaQueryWrapper 示例
List<User> list = userMapper.selectList(
    new LambdaQueryWrapper<User>()
        .eq(User::getStatus, 1)
        .like(User::getUsername, "张")
        .orderByDesc(User::getCreatedAt)
);
```

## 分页插件

配置分页拦截器：

```java
@Bean
public MybatisPlusInterceptor mybatisPlusInterceptor() {
    MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
    interceptor.addInnerInterceptor(new PaginationInnerInterceptor(DbType.MYSQL));
    return interceptor;
}
```

使用分页：

```java
Page<User> page = new Page<>(1, 10); // 第1页，每页10条
userMapper.selectPage(page, null);
System.out.println("总条数：" + page.getTotal());
```

## 逻辑删除

在 `application.yml` 中配置：

```yaml
mybatis-plus:
  global-config:
    db-config:
      logic-delete-field: deleted
      logic-delete-value: 1
      logic-not-delete-value: 0
```

实体类加 `@TableLogic` 注解，之后调用 `deleteById` 实际上会执行 `UPDATE ... SET deleted=1`。',
'MyBatis-Plus 常用功能速查，包含基础 CRUD、条件构造器 LambdaQueryWrapper、分页插件配置和逻辑删除的使用示例。', 3, 1, 0),

(3, 'Spring Security + JWT 实现无状态鉴权',
'# Spring Security + JWT 实现无状态鉴权

## 整体流程

```
登录请求 → AuthController → UserService → 验证密码 → 生成 JWT → 返回 Token
后续请求 → JwtFilter → 解析 Token → 设置 SecurityContext → 放行
注销请求 → 将 Token 加入 Redis 黑名单 → 前端删除 Token
```

## JWT 结构

JWT 由三部分组成，用 `.` 分隔：
- **Header**：算法类型（如 HS256）
- **Payload**：自定义数据（userId、username、过期时间等）
- **Signature**：使用密钥对 Header+Payload 签名，防篡改

## 关键代码

生成 Token：

```java
public String generateToken(Long userId, String username, Integer role) {
    return Jwts.builder()
            .subject(String.valueOf(userId))
            .claim("username", username)
            .claim("role", role)
            .expiration(new Date(System.currentTimeMillis() + expiration))
            .signWith(getKey())
            .compact();
}
```

过滤器解析 Token：

```java
Long userId = jwtUtil.getUserId(token);
Integer role = jwtUtil.getRole(token);
List<SimpleGrantedAuthority> authorities = new ArrayList<>();
authorities.add(new SimpleGrantedAuthority("ROLE_USER"));
if (role == 1) authorities.add(new SimpleGrantedAuthority("ROLE_ADMIN"));
```

## Redis 黑名单

注销时将 Token 存入 Redis，剩余有效期与 Token 一致：

```java
long remaining = jwtUtil.getExpiration(token) - System.currentTimeMillis();
redisTemplate.opsForValue().set("blacklist:" + token, "1", remaining, TimeUnit.MILLISECONDS);
```',
'Spring Security + JWT 实现无状态鉴权的完整方案，包含 JWT 生成、过滤器解析、Redis Token 黑名单（注销防复用）三大环节。', 3, 1, 0),

(4, 'RAG（检索增强生成）技术详解',
'# RAG（检索增强生成）技术详解

## 什么是 RAG？

RAG（Retrieval-Augmented Generation）是一种将**信息检索**与**生成式 AI** 结合的技术范式。它解决了大语言模型的两个核心痛点：

1. **知识截止问题**：LLM 训练数据有截止日期，无法获取最新信息
2. **幻觉问题**：LLM 可能生成看似合理但实际错误的内容

## 工作流程

### 离线阶段（索引构建）

```
原始文档 → 文本分块（Chunking） → Embedding 向量化 → 存入向量数据库
```

### 在线阶段（问答）

```
用户问题 → 向量化 → 相似度检索 → 召回相关片段
→ 拼接 Prompt → 调用 LLM → 生成答案（附来源引用）
```

## 关键技术点

### 文本分块策略

- **固定大小**：按字符数切分，简单但可能截断语义
- **语义分块**：按段落/句子切分，保持语义完整
- **Chunk 大小**：通常 512-1024 Token，需要结合检索效果调整

### 向量相似度

常用度量：
- **余弦相似度**（Cosine Similarity）：最常用，衡量方向相似性
- **点积**（Dot Product）：计算快，适合归一化向量
- **欧氏距离**（L2）：适合密集向量

### Prompt 构建模板

```
你是一个知识助手，请严格基于以下知识库内容回答问题，不要捏造信息。
如果知识库中没有相关内容，请如实告知用户"知识库中暂无相关内容"。

知识库内容：
{retrieved_chunks}

用户问题：{user_question}
```

## Spring AI 中的 RAG 实现

```java
// 向量化存储
vectorStore.add(List.of(Document.builder()
    .text(knowledge.getTitle() + "\n" + knowledge.getContent())
    .metadata(Map.of("knowledgeId", knowledge.getId().toString()))
    .build()));

// 相似度检索
List<Document> docs = vectorStore.similaritySearch(
    SearchRequest.builder().query(question).topK(3).similarityThreshold(0.6).build()
);
```',
'RAG（检索增强生成）技术的完整详解，涵盖工作流程、文本分块策略、向量相似度计算和 Spring AI 中的具体实现代码。', 11, 1, 0),

(5, 'Vue 3 Composition API 核心用法',
'# Vue 3 Composition API 核心用法

## 为什么使用 Composition API？

相比 Vue 2 的 Options API，Composition API 的优势：
- **逻辑复用**：通过自定义 Hooks（Composables）提取可复用逻辑
- **类型推断**：对 TypeScript 更友好
- **代码组织**：相关逻辑放在一起，不再被 data/methods/computed 强制分散

## 核心函数

### ref 和 reactive

```javascript
import { ref, reactive } from "vue"

// ref：适合基本类型
const count = ref(0)
count.value++ // 访问时需要 .value

// reactive：适合对象
const state = reactive({ name: "", age: 0 })
state.name = "张三"  // 直接访问，不需要 .value
```

### computed 和 watch

```javascript
import { computed, watch } from "vue"

// 计算属性
const doubled = computed(() => count.value * 2)

// 监听
watch(count, (newVal, oldVal) => {
  console.log(`count 从 ${oldVal} 变为 ${newVal}`)
})

// 立即执行 + 深度监听
watch(state, (val) => { ... }, { immediate: true, deep: true })
```

### 生命周期

```javascript
import { onMounted, onUnmounted } from "vue"

onMounted(() => {
  console.log("组件已挂载")
})

onUnmounted(() => {
  console.log("组件已卸载，清理资源")
})
```

## 自定义 Composable

```javascript
// useCounter.js
import { ref } from "vue"

export function useCounter(initial = 0) {
  const count = ref(initial)
  const increment = () => count.value++
  const decrement = () => count.value--
  return { count, increment, decrement }
}

// 在组件中使用
const { count, increment } = useCounter(10)
```

## Pinia 状态管理

```javascript
// stores/user.js
import { defineStore } from "pinia"

export const useUserStore = defineStore("user", {
  state: () => ({ token: localStorage.getItem("token") || "" }),
  actions: {
    setToken(token) { this.token = token; localStorage.setItem("token", token) },
    logout() { this.token = ""; localStorage.removeItem("token") }
  }
})
```',
'Vue 3 Composition API 核心用法，包含 ref/reactive、computed/watch、生命周期钩子、自定义 Composable 和 Pinia 状态管理的实用示例。', 6, 1, 0),

(6, 'MySQL 索引原理与优化实践',
'# MySQL 索引原理与优化实践

## 索引底层结构：B+ 树

MySQL InnoDB 使用 **B+ 树**作为索引结构：
- 非叶子节点只存储键值，叶子节点存储完整数据
- 叶子节点之间有双向链表，支持范围查询
- 树高一般为 3-4 层，3 次磁盘 IO 可定位千万级数据

## 索引类型

| 类型 | 说明 |
|------|------|
| 主键索引（聚簇索引） | 数据按主键顺序存储，叶子节点包含完整行数据 |
| 普通索引（二级索引） | 叶子节点存储主键值，查询数据需"回表" |
| 联合索引 | 多列组合，遵循最左前缀原则 |
| 全文索引（FULLTEXT） | 用于文本内容的模糊搜索，本系统使用 ngram 分词器 |

## 本系统的全文索引

```sql
-- 建表时创建 ngram 全文索引
FULLTEXT KEY `ft_title_content` (`title`, `content`) WITH PARSER ngram

-- 使用 MATCH...AGAINST 进行全文搜索
SELECT * FROM knowledge
WHERE MATCH(title, content) AGAINST (\'Spring Boot\' IN BOOLEAN MODE);
```

## 索引优化原则

1. **最左前缀原则**：联合索引 (a, b, c)，查询条件必须包含 a
2. **避免在索引列做运算**：`WHERE YEAR(created_at) = 2024` 不走索引
3. **覆盖索引**：查询字段全部在索引中，无需回表
4. **区分度低的列不建索引**：如性别字段（只有 0/1）
5. **EXPLAIN 分析执行计划**：

```sql
EXPLAIN SELECT * FROM knowledge WHERE user_id = 1;
-- 关注 type 字段：const > eq_ref > ref > range > ALL
-- type=ALL 说明全表扫描，需要优化
```',
'MySQL 索引原理（B+树结构）与优化实践，涵盖索引类型对比、全文索引 ngram 分词器使用、最左前缀原则和 EXPLAIN 执行计划分析。', 8, 1, 0),

(7, 'Redis 常用数据结构与使用场景',
'# Redis 常用数据结构与使用场景

## 五大基础数据结构

### String（字符串）
最常用，值可以是字符串、整数或二进制数据，最大 512MB。

```
SET key value EX 3600    # 设置并设过期时间（秒）
GET key
INCR counter             # 原子自增，适合计数器
```

**场景**：缓存、计数器、分布式锁、JWT 黑名单

### Hash（哈希表）
存储对象的多个字段，比每个字段单独存 String 更省内存。

```
HSET user:1 name "张三" age 18
HGET user:1 name
HGETALL user:1
```

### List（列表）
双向链表，支持头尾操作。

```
LPUSH queue task1 task2    # 左侧插入
RPOP queue                 # 右侧弹出
```

**场景**：消息队列、最新动态列表

### Set（集合）
无序不重复，支持交并差集运算。

**场景**：用户标签、共同好友、去重

### ZSet（有序集合）
每个元素关联一个 score，按 score 排序。

```
ZADD leaderboard 100 "player1"
ZRANGE leaderboard 0 9 WITHSCORES REV    # 取前10名
```

**场景**：排行榜、延迟队列

## 本系统中 Redis 的用途

```java
// JWT Token 黑名单（注销防复用）
redisTemplate.opsForValue().set(
    "blacklist:" + token,
    "1",
    remaining,          // 剩余有效期
    TimeUnit.MILLISECONDS
);

// 检查是否在黑名单
redisTemplate.hasKey("blacklist:" + token);
```',
'Redis 五大基础数据结构（String/Hash/List/Set/ZSet）的命令速查与使用场景，以及本系统中用 Redis 实现 JWT 黑名单的具体代码。', 9, 1, 0),

(8, 'DeepSeek API 接入指南',
'# DeepSeek API 接入指南

## 为什么选择 DeepSeek？

- **性价比极高**：价格约为 OpenAI GPT-4o 的 1/30
- **OpenAI 兼容**：API 完全兼容 OpenAI 协议，无需改代码只改配置
- **中文能力强**：对中文理解和生成质量出色
- **支持流式输出**：原生支持 SSE streaming

## Spring AI 接入配置

在 `application.yml` 中配置：

```yaml
spring:
  ai:
    openai:
      api-key: sk-xxxxxxxxxxxxxxxx   # DeepSeek 官网申请
      base-url: https://api.deepseek.com
      chat:
        options:
          model: deepseek-chat       # 通用模型
          temperature: 0.7
```

## 可用模型

| 模型 | 特点 | 适用场景 |
|------|------|---------|
| deepseek-chat | 速度快，综合能力强 | 日常问答、摘要、标签推荐 |
| deepseek-reasoner | 强推理（R1），支持思维链 | 复杂逻辑、数学推理 |

## 流式输出实现

后端（Spring AI + WebFlux）：

```java
return chatClient.prompt()
        .system(systemPrompt)
        .user(question)
        .stream()
        .content();  // 返回 Flux<String>
```

前端（fetch + ReadableStream）：

```javascript
const response = await fetch(url, {
  headers: { Authorization: `Bearer ${token}` }
})
const reader = response.body.getReader()
while (true) {
  const { done, value } = await reader.read()
  if (done) break
  const text = new TextDecoder().decode(value)
  // 处理 SSE 格式：data: xxx
  text.split("\\n").forEach(line => {
    if (line.startsWith("data: ")) {
      onToken(line.slice(6).trim())
    }
  })
}
```

## 费用估算

- 普通问答：约 ¥0.005/次
- AI 摘要：约 ¥0.003/次
- 开发调试全程：¥1～5 元',
'DeepSeek API 在 Spring AI 中的接入配置、可用模型对比、流式输出前后端实现代码，以及费用估算参考。', 12, 1, 0);

-- ================================================================
-- 知识-标签关联
-- ================================================================
INSERT IGNORE INTO `knowledge_tag` (`knowledge_id`, `tag_id`) VALUES
(1, 2), (1, 12),            -- Spring Boot 快速入门
(2, 11), (2, 12), (2, 1),  -- MyBatis-Plus
(3, 10), (3, 2), (3, 6),   -- JWT 鉴权
(4, 7), (4, 8), (4, 14),   -- RAG
(5, 4), (5, 13),            -- Vue 3
(6, 5), (6, 12),            -- MySQL
(7, 6), (7, 12),            -- Redis
(8, 9), (8, 8), (8, 3);    -- DeepSeek

-- ================================================================
-- 扩充数据：开发技术 + 人工智能领域
-- 新增 13 个分类 | 10 个标签 | 10 篇知识文章
-- ================================================================

-- 新增分类（IDs 13–25）
-- 新增根节点：DevOps / 微服务架构 / Python / 工具与效率
-- 在已有根节点下新增：人工智能 → Prompt工程/AI Agent；前端 → TypeScript；数据库 → Elasticsearch
INSERT INTO `category` (`id`, `name`, `parent_id`, `user_id`, `sort`) VALUES
(13, 'DevOps',         0,  1, 5),
(14, 'Docker',        13,  1, 1),
(15, 'Kubernetes',    13,  1, 2),
(16, '微服务架构',     0,  1, 6),
(17, 'Spring Cloud',  16,  1, 1),
(18, 'Python',         0,  1, 7),
(19, 'FastAPI',       18,  1, 1),
(20, '工具与效率',     0,  1, 8),
(21, 'Git',           20,  1, 1),
(22, 'Prompt 工程',   10,  1, 3),
(23, 'AI Agent',      10,  1, 4),
(24, 'TypeScript',     5,  1, 2),
(25, 'Elasticsearch',  7,  1, 3);

-- 新增标签（IDs 15–24）
INSERT INTO `tag` (`id`, `name`, `user_id`) VALUES
(15, 'Docker',        1),
(16, 'Kubernetes',    1),
(17, 'Spring Cloud',  1),
(18, 'Python',        1),
(19, 'FastAPI',       1),
(20, 'Git',           1),
(21, 'Prompt工程',    1),
(22, 'AI Agent',      1),
(23, 'TypeScript',    1),
(24, 'Elasticsearch', 1);

-- ================================================================
-- 新增知识条目（IDs 9–18）
-- ================================================================
INSERT INTO `knowledge` (`id`, `title`, `content`, `summary`, `category_id`, `user_id`, `is_vectorized`) VALUES

(9, 'Docker 容器化部署实践',
'# Docker 容器化部署实践

## 核心概念

| 概念 | 说明 |
|------|------|
| 镜像（Image） | 只读模板，包含运行应用所需的全部文件和环境 |
| 容器（Container） | 镜像的运行实例，进程级隔离，轻量高效 |
| Dockerfile | 描述如何一步步构建镜像的脚本文件 |
| Registry | 镜像仓库，如 Docker Hub、阿里云 ACR |
| Docker Compose | 多容器编排工具，用 YAML 定义服务拓扑 |

## Dockerfile 多阶段构建（Spring Boot）

多阶段构建让最终镜像只包含 JRE，不含 JDK 和 Maven，体积缩小约 60%：

```dockerfile
# 阶段1：Maven 构建
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn package -DskipTests

# 阶段2：只保留 JRE 运行时
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## Docker Compose 多服务编排

```yaml
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: zhizhi
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  backend:
    build: ./zhizhi-backend
    ports:
      - "8080:8080"
    depends_on:
      mysql:
        condition: service_healthy
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/zhizhi
      SPRING_REDIS_HOST: redis

volumes:
  mysql_data:
```

## 常用命令速查

```bash
docker build -t my-app:1.0 .           # 构建镜像
docker run -d -p 8080:8080 my-app:1.0  # 后台运行容器
docker ps                               # 查看运行中的容器
docker logs -f <container_id>           # 实时跟踪日志
docker exec -it <container_id> sh       # 进入容器
docker-compose up -d                    # 后台启动所有服务
docker-compose down                     # 停止并清理容器
docker system prune -f                  # 清理无用镜像和容器
```

## 优化要点

1. **使用 Alpine 基础镜像**：`eclipse-temurin:21-jre-alpine` 比标准版小约 60%
2. **多阶段构建**：构建产物与运行环境分离，最终镜像不含构建工具
3. **利用构建缓存**：先 COPY pom.xml 安装依赖，再 COPY src，代码变更时无需重新下载依赖
4. **.dockerignore**：排除 target/、.git/、node_modules/ 等目录，加速构建上下文传输',
'Docker 容器化完整实践，涵盖核心概念对比、Spring Boot 多阶段 Dockerfile 构建、Docker Compose 多服务编排配置，以及镜像体积优化的四大技巧。', 14, 1, 0),

(10, 'Spring Cloud 微服务核心组件',
'# Spring Cloud 微服务核心组件

## 什么是微服务架构？

微服务将一个大型单体应用拆分为多个**独立部署、独立扩展**的小服务，每个服务只负责单一业务域，通过 HTTP/RPC 相互调用。

## 核心组件速览

| 组件 | 选型推荐 | 职责 |
|------|---------|------|
| 服务注册与发现 | Nacos | 服务实例注册、健康检查、动态发现 |
| 远程调用 | OpenFeign | 声明式 HTTP 客户端，屏蔽底层 RestTemplate |
| API 网关 | Spring Cloud Gateway | 统一入口、路由、鉴权、限流 |
| 配置中心 | Nacos Config | 集中管理配置，支持热更新 |
| 熔断限流 | Sentinel | 流量控制、熔断降级、系统保护 |
| 链路追踪 | Micrometer Tracing | 分布式链路，对接 Zipkin/Jaeger |

## Nacos 服务注册

pom.xml 引入依赖：

```xml
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
</dependency>
```

application.yml 配置：

```yaml
spring:
  application:
    name: order-service        # 服务名，注册到 Nacos 的唯一标识
  cloud:
    nacos:
      discovery:
        server-addr: 127.0.0.1:8848
```

## OpenFeign 远程调用

声明式客户端，像调用本地方法一样调用远程服务：

```java
@FeignClient(name = "user-service", fallback = UserClientFallback.class)
public interface UserClient {
    @GetMapping("/api/users/{id}")
    UserVO getUserById(@PathVariable Long id);
}
```

使用时直接注入调用：

```java
@Autowired
private UserClient userClient;

UserVO user = userClient.getUserById(userId);
```

## Sentinel 流量控制

```java
@SentinelResource(
    value = "getUserById",
    blockHandler = "blockHandler",   // QPS 超限时走此方法
    fallback = "fallbackHandler"     // 抛异常时降级
)
public UserVO getUserById(Long id) {
    return userClient.getUserById(id);
}
```

## 服务间通信最佳实践

- **同步调用**：OpenFeign（HTTP），适合实时查询
- **异步解耦**：RocketMQ / RabbitMQ，适合订单、通知等场景
- **幂等设计**：网络重试时避免重复处理，推荐唯一请求 ID + 数据库唯一索引
- **超时配置**：Feign 连接超时 3s，读取超时 10s，避免雪崩',
'Spring Cloud 微服务核心组件全景：Nacos 服务注册发现、OpenFeign 声明式远程调用、Spring Cloud Gateway 网关、Sentinel 熔断限流的配置示例与使用规范。', 17, 1, 0),

(11, 'Python + FastAPI 快速开发 REST API',
'# Python + FastAPI 快速开发 REST API

## 为什么选择 FastAPI？

- **极致性能**：基于 Starlette + Uvicorn，性能媲美 Node.js
- **自动文档**：内置 Swagger UI 和 ReDoc，零配置即可访问 `/docs`
- **类型驱动**：基于 Python 类型注解 + Pydantic，自动完成请求校验和序列化
- **异步原生**：支持 `async/await`，轻松处理高并发 IO 操作

## 安装与快速启动

```bash
pip install fastapi uvicorn[standard] pydantic
uvicorn main:app --reload --port 8000
```

## 最简示例

```python
from fastapi import FastAPI

app = FastAPI(title="知识助手 API", version="1.0.0")

@app.get("/")
async def root():
    return {"message": "Hello, ZhiZhi!"}

@app.get("/items/{item_id}")
async def get_item(item_id: int, q: str = None):
    return {"item_id": item_id, "q": q}
```

## 请求体与数据校验（Pydantic）

```python
from pydantic import BaseModel, Field
from typing import Optional

class KnowledgeCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, description="标题")
    content: str = Field(..., description="Markdown 正文")
    category_id: Optional[int] = None

@app.post("/knowledge/", status_code=201)
async def create_knowledge(body: KnowledgeCreate):
    # body 已完成类型校验和转换
    return {"id": 1, **body.model_dump()}
```

## 依赖注入（Depends）

```python
from fastapi import Depends, HTTPException, Header

async def get_current_user(authorization: str = Header(...)):
    token = authorization.removeprefix("Bearer ")
    user = verify_jwt(token)
    if not user:
        raise HTTPException(status_code=401, detail="未授权")
    return user

@app.get("/profile")
async def get_profile(user = Depends(get_current_user)):
    return user
```

## 异步数据库操作（SQLAlchemy async）

```python
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

engine = create_async_engine("mysql+aiomysql://root:123456@localhost/zhizhi")

async def get_db():
    async with AsyncSession(engine) as session:
        yield session

@app.get("/knowledge/{id}")
async def get_knowledge(id: int, db: AsyncSession = Depends(get_db)):
    result = await db.get(Knowledge, id)
    return result
```

## 与 Spring Boot 对比

| 维度 | FastAPI | Spring Boot |
|------|---------|-------------|
| 语言 | Python | Java |
| 启动速度 | 极快（秒级） | 较慢（数秒至十几秒） |
| AI/ML 生态 | 极丰富（PyTorch、HuggingFace） | 需借助 Python 服务 |
| 企业级特性 | 需自行集成 | 开箱即用 |
| 适合场景 | AI 服务、数据处理、快速原型 | 企业后台、复杂业务系统 |',
'Python FastAPI 完整入门，包含 Pydantic 数据校验、Depends 依赖注入、async/await 异步数据库操作，以及与 Spring Boot 的适用场景对比。', 19, 1, 0),

(12, 'Elasticsearch 全文检索实践',
'# Elasticsearch 全文检索实践

## 核心概念

| ES 概念 | 类比 MySQL | 说明 |
|---------|-----------|------|
| Index | Table | 文档的集合，类似表 |
| Document | Row | 一条数据，JSON 格式 |
| Field | Column | 文档中的字段 |
| Shard | 分区 | 索引的物理分片，支持水平扩展 |
| Replica | 从库 | 分片的副本，提升可用性 |

## 为什么不用 MySQL 全文索引？

- MySQL ngram 全文索引适合**中小数据量**和**简单搜索**
- ES 支持**更丰富的查询 DSL**（布尔查询、模糊查询、高亮、聚合）
- ES 支持**近实时**（NRT）搜索，写入后约 1 秒可查到
- ES 天然支持**水平扩展**，亿级文档毫秒级响应

## REST API 基本操作

```bash
# 创建索引
PUT /knowledge
{
  "mappings": {
    "properties": {
      "title":   { "type": "text", "analyzer": "ik_max_word" },
      "content": { "type": "text", "analyzer": "ik_max_word" },
      "userId":  { "type": "long" },
      "createdAt": { "type": "date" }
    }
  }
}

# 写入文档
PUT /knowledge/_doc/1
{ "title": "Spring Boot 3 快速入门", "content": "...", "userId": 1 }

# 删除文档
DELETE /knowledge/_doc/1
```

## Query DSL 复杂查询

布尔查询（must + filter）：

```json
GET /knowledge/_search
{
  "query": {
    "bool": {
      "must": [
        { "multi_match": {
            "query": "Spring Boot",
            "fields": ["title^2", "content"],
            "type": "best_fields"
        }}
      ],
      "filter": [
        { "term": { "userId": 1 } }
      ]
    }
  },
  "highlight": {
    "fields": { "title": {}, "content": { "fragment_size": 150 } }
  },
  "from": 0,
  "size": 10
}
```

`title^2` 表示标题字段的权重是正文的 2 倍。

## Spring Data Elasticsearch 集成

```java
@Document(indexName = "knowledge")
public class KnowledgeDoc {
    @Id
    private Long id;
    @Field(type = FieldType.Text, analyzer = "ik_max_word")
    private String title;
    @Field(type = FieldType.Text, analyzer = "ik_max_word")
    private String content;
}

@Repository
public interface KnowledgeEsRepository extends ElasticsearchRepository<KnowledgeDoc, Long> {
    List<KnowledgeDoc> findByTitleContainingOrContentContaining(String title, String content);
}
```

## IK 中文分词器

ES 默认不支持中文分词，需安装 IK 插件：

```bash
./bin/elasticsearch-plugin install https://github.com/infinilabs/analysis-ik/releases/download/v8.13.0/elasticsearch-analysis-ik-8.13.0.zip
```

- `ik_max_word`：细粒度分词，适合**索引**
- `ik_smart`：粗粒度分词，适合**查询**',
'Elasticsearch 全文检索完整实践：核心概念与 MySQL 对比、REST API 基本操作、布尔查询 DSL 与高亮配置、Spring Data ES 集成，以及 IK 中文分词器安装说明。', 25, 1, 0),

(13, 'Git 工作流与分支管理策略',
'# Git 工作流与分支管理策略

## 三种主流工作流对比

| 工作流 | 适合场景 | 核心思想 |
|--------|---------|---------|
| Git Flow | 有固定发版周期的项目 | main + develop + feature/release/hotfix 多分支并行 |
| GitHub Flow | 持续交付、小团队 | 只有 main，功能分支合并即部署 |
| Trunk-Based | 大型团队、高频发布 | 所有人直接推主干，配合 Feature Flag |

推荐个人/小团队项目使用 **GitHub Flow**，简单直接。

## GitHub Flow 实践

```bash
# 1. 从 main 创建功能分支
git checkout -b feat/knowledge-search

# 2. 开发并提交
git add .
git commit -m "feat: 添加全文搜索功能"

# 3. 推送并创建 PR
git push origin feat/knowledge-search

# 4. Code Review 通过后合并到 main
# 5. main 合并后立即触发 CI/CD 部署
```

## Commit Message 规范（Conventional Commits）

格式：`<type>(<scope>): <subject>`

| type | 含义 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| docs | 文档变更 |
| refactor | 重构（不改变功能） |
| perf | 性能优化 |
| test | 测试相关 |
| chore | 构建/工具链变更 |

示例：
```
feat(knowledge): 新增知识条目全文搜索接口
fix(auth): 修复 Token 刷新时并发导致的重复签发问题
docs: 更新 API 接口文档
```

## 常用命令速查

```bash
# 分支管理
git branch -a                    # 查看所有分支
git checkout -b feat/xxx         # 新建并切换分支
git branch -d feat/xxx           # 删除本地分支

# 撤销操作
git restore <file>               # 撤销工作区修改
git reset HEAD~1                 # 撤销最近一次提交（保留修改）
git revert <commit>              # 安全回退（生成新提交）

# 同步
git fetch origin                 # 拉取远端更新（不合并）
git pull --rebase origin main    # 变基方式拉取，保持线性历史
git stash                        # 暂存当前改动
git stash pop                    # 恢复暂存

# 查看历史
git log --oneline --graph        # 可视化提交树
git blame <file>                 # 查看每行最后一次修改者
```

## 处理合并冲突

```bash
git merge main                   # 合并时遇到冲突
# 手动编辑冲突文件，解决 <<<<<<< / ======= / >>>>>>> 标记
git add <resolved-file>
git commit                       # 提交合并结果
```

## .gitignore 最佳实践

Java 项目必须忽略：

```
target/
*.class
.idea/
*.iml
application-local.yml            # 本地敏感配置不入库
```',
'Git 工作流与分支管理完整指南：三种主流工作流（Git Flow / GitHub Flow / Trunk-Based）对比、Conventional Commits 规范、常用命令速查，以及合并冲突处理流程。', 21, 1, 0),

(14, 'Prompt Engineering 提示词工程核心技巧',
'# Prompt Engineering 提示词工程核心技巧

## 什么是 Prompt Engineering？

Prompt Engineering（提示词工程）是通过精心设计输入文本来引导大语言模型（LLM）产生更准确、更符合期望的输出的技术。好的 Prompt 能将模型能力发挥到极致，差的 Prompt 则导致幻觉或无效回复。

## 核心原则

1. **明确角色**：告诉模型它是谁
2. **给出上下文**：提供足够的背景信息
3. **指定格式**：明确期望的输出格式
4. **设置约束**：限制不需要的内容
5. **提供示例**：展示期望的输入输出样例

## 六大核心技巧

### 1. 角色设定（Role Prompting）

```
你是一位有 10 年经验的 Java 后端架构师，擅长 Spring Cloud 微服务和高并发系统设计。
请以专业架构师的视角回答以下问题：
```

### 2. 少样本学习（Few-Shot）

```
将以下 Java 命名转为 Python 风格：

示例1：getUserById → get_user_by_id
示例2：findAllActiveUsers → find_all_active_users

现在转换：parseJsonResponse →
```

### 3. 思维链（Chain of Thought, CoT）

```
请一步步分析这段代码的时间复杂度，不要直接给出答案，
先分析外层循环，再分析内层循环，最后得出结论。
```

### 4. 结构化输出

```
分析以下代码，以 JSON 格式返回结果：
{
  "bugs": ["bug1", "bug2"],
  "suggestions": ["suggestion1"],
  "complexity": "O(n²)"
}
```

### 5. RAG 系统 Prompt 模板

```
你是一个专业的知识助手，请严格基于以下知识库内容回答问题。
不要捏造知识库中没有的信息。
如果知识库中没有相关内容，请回答："知识库中暂无相关内容，请补充。"

【知识库内容】
{retrieved_context}

【用户问题】
{user_question}

【回答要求】
- 语言简洁，重点突出
- 如引用知识库内容，请注明来源标题
```

### 6. 自我反思（Self-Reflection）

```
请先给出你的答案，然后检查答案是否有逻辑漏洞或事实错误，
最后给出修正后的最终答案。
```

## 常见反模式

| 反模式 | 问题 | 改进方向 |
|--------|------|---------|
| 过于模糊 | "帮我写代码" | 明确语言、功能、约束条件 |
| 无示例 | 期望特定格式但不说明 | 提供 1-3 个 input/output 示例 |
| 指令矛盾 | "简洁但要全面" | 优先级排序，明确取舍 |
| 忽略角色 | 直接问问题 | 设定合适的专业角色 |

## Temperature 参数调优

| 场景 | Temperature | 说明 |
|------|------------|------|
| 代码生成、SQL | 0.0–0.3 | 需要确定性、准确性 |
| 问答、摘要 | 0.5–0.7 | 平衡准确与流畅 |
| 创意写作、头脑风暴 | 0.8–1.0 | 鼓励多样性和创造性 |',
'Prompt Engineering 六大核心技巧：角色设定、Few-Shot 少样本、Chain of Thought 思维链、结构化输出、RAG 系统 Prompt 模板，以及 Temperature 参数调优指南和常见反模式分析。', 22, 1, 0),

(15, 'AI Agent 自主智能体架构设计',
'# AI Agent 自主智能体架构设计

## 什么是 AI Agent？

AI Agent（人工智能体）是一种能够**感知环境、规划行动、调用工具、执行任务**的自主 AI 系统。与普通 LLM 问答的区别：

| 普通 LLM | AI Agent |
|----------|---------|
| 单次问答，无状态 | 多轮规划，有记忆 |
| 只能生成文本 | 可调用工具（搜索、代码执行、API） |
| 人驱动 | 自主决策下一步动作 |

## ReAct 架构（Reasoning + Acting）

ReAct 是最主流的 Agent 推理框架，让 LLM 交替进行思考和行动：

```
Thought: 我需要查询用户最近的知识条目
Action: search_knowledge(user_id=1, limit=5)
Observation: [{"id":1,"title":"Spring Boot 3 快速入门",...}]
Thought: 已获得结果，可以回答用户
Answer: 您最近添加的知识条目是...
```

## Function Calling（工具调用）

现代 LLM 通过 Function Calling 调用外部工具：

```python
tools = [
    {
        "type": "function",
        "function": {
            "name": "search_knowledge",
            "description": "在知识库中搜索相关内容",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "搜索关键词"},
                    "top_k": {"type": "integer", "default": 3}
                },
                "required": ["query"]
            }
        }
    }
]

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[{"role": "user", "content": "帮我找 Spring Boot 相关的笔记"}],
    tools=tools,
    tool_choice="auto"
)
```

## Spring AI 中的 Agent 实现

```java
@Bean
public ChatClient agentChatClient(ChatClient.Builder builder) {
    return builder
        .defaultSystem("你是知识助手，可以调用工具搜索知识库")
        .defaultTools(knowledgeSearchTool, summaryTool)
        .build();
}

// 工具定义
@Tool(description = "搜索知识库中的相关内容")
public String searchKnowledge(String query) {
    return ragService.search(query);
}
```

## 多 Agent 协作模式

```
用户请求
    ↓
协调者 Agent（Orchestrator）
    ├→ 搜索 Agent：检索知识库
    ├→ 分析 Agent：提炼关键信息
    └→ 写作 Agent：生成最终回复
```

常见多 Agent 框架：
- **LangGraph**：基于图的 Agent 工作流，支持循环和条件分支
- **AutoGen**：微软开源，适合多 Agent 对话协作
- **CrewAI**：角色驱动的多 Agent 任务编排

## Agent 设计原则

1. **工具原子化**：每个工具只做一件事，便于组合
2. **记忆分层**：短期记忆（对话历史）+ 长期记忆（向量知识库）
3. **错误恢复**：工具调用失败时能自动重试或选择备选方案
4. **人机协同**：关键决策节点加入人工审批（Human-in-the-Loop）
5. **可观测性**：记录每一步 Thought/Action/Observation，便于调试',
'AI Agent 自主智能体完整解析：ReAct 推理框架、Function Calling 工具调用实现、Spring AI Agent 代码示例、多 Agent 协作模式（LangGraph/AutoGen/CrewAI），以及 Agent 工程设计原则。', 23, 1, 0),

(16, 'TypeScript 核心类型系统速查',
'# TypeScript 核心类型系统速查

## 为什么使用 TypeScript？

- **编译期类型检查**：在运行前发现类型错误，而非等到生产出 Bug
- **IDE 智能提示**：精准的自动补全，大幅提升开发效率
- **重构安全**：改变函数签名后，所有调用处会立即报错
- **与 Vue 3 完美配合**：`<script setup lang="ts">` 开箱即用

## 基础类型

```typescript
// 原始类型
let id: number = 1
let name: string = "张三"
let active: boolean = true
let nothing: null = null
let undef: undefined = undefined

// 数组
let ids: number[] = [1, 2, 3]
let names: Array<string> = ["a", "b"]

// 元组（固定长度和类型）
let point: [number, number] = [10, 20]

// 联合类型
let status: "active" | "inactive" | "banned" = "active"

// 可选类型
let email: string | null = null
```

## 接口（Interface）vs 类型别名（Type）

```typescript
// Interface：描述对象形状，可以 extends 和 implements
interface User {
    id: number
    name: string
    email?: string            // 可选字段
    readonly createdAt: Date  // 只读字段
}

// Type Alias：更灵活，可以表示联合类型、交叉类型
type ID = number | string
type Admin = User & { permissions: string[] }  // 交叉类型

// 优先使用 Interface 描述对象，Type 用于联合/交叉/工具类型
```

## 泛型

```typescript
// 泛型函数
function first<T>(arr: T[]): T | undefined {
    return arr[0]
}

// 泛型接口
interface ApiResponse<T> {
    code: number
    message: string
    data: T
}

// 使用
const res: ApiResponse<User> = await fetchUser(1)
const user: User = res.data
```

## 内置工具类型

```typescript
interface Knowledge {
    id: number
    title: string
    content: string
    categoryId: number
}

// Partial：所有字段变为可选（适合 PATCH 请求体）
type KnowledgeUpdate = Partial<Knowledge>

// Required：所有字段变为必填
type KnowledgeRequired = Required<Knowledge>

// Pick：取出部分字段
type KnowledgeSummary = Pick<Knowledge, "id" | "title">

// Omit：排除部分字段
type KnowledgeCreate = Omit<Knowledge, "id">

// Record：构建键值映射
type CategoryMap = Record<number, string>
```

## Vue 3 + TypeScript 示例

```typescript
<script setup lang="ts">
import { ref, computed } from "vue"

interface Knowledge {
    id: number
    title: string
    content: string
}

const list = ref<Knowledge[]>([])
const keyword = ref("")

const filtered = computed(() =>
    list.value.filter(k => k.title.includes(keyword.value))
)

async function loadList(): Promise<void> {
    const res = await fetch("/api/knowledge")
    list.value = await res.json() as Knowledge[]
}
</script>
```

## 常用类型体操

```typescript
// 深度只读
type DeepReadonly<T> = { readonly [K in keyof T]: DeepReadonly<T[K]> }

// 提取函数返回类型
type UnwrapPromise<T> = T extends Promise<infer R> ? R : T

// 非空断言（确定不为 null/undefined 时使用）
const el = document.getElementById("app")!
```',
'TypeScript 核心类型系统完整速查：基础类型、Interface vs Type Alias、泛型函数与接口、Partial/Required/Pick/Omit 等内置工具类型，以及 Vue 3 + TypeScript 实战示例。', 24, 1, 0),

(17, 'Kubernetes 入门与核心概念',
'# Kubernetes 入门与核心概念

## 为什么需要 Kubernetes？

Docker 只能管理**单机**上的容器。当服务规模扩大，需要：
- 跨多台服务器部署容器
- 自动故障恢复（某个节点挂掉，容器自动迁移）
- 弹性扩缩容（流量高峰自动增加实例）
- 滚动更新（不停机发布新版本）

这就是 Kubernetes（K8s）要解决的问题。

## 核心概念

| 资源 | 说明 |
|------|------|
| Pod | 最小调度单位，一个或多个容器的集合，共享网络和存储 |
| Deployment | 管理 Pod 副本数，支持滚动更新和回滚 |
| Service | 为 Pod 提供稳定的访问入口（ClusterIP/NodePort/LoadBalancer） |
| ConfigMap | 存储非敏感配置信息 |
| Secret | 存储敏感信息（密码、Token），Base64 编码 |
| Namespace | 集群内的逻辑隔离，如 dev/staging/prod |
| Ingress | HTTP 路由规则，类似反向代理 |

## 部署一个 Spring Boot 应用

Deployment YAML：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zhizhi-backend
  namespace: production
spec:
  replicas: 3                        # 运行 3 个副本
  selector:
    matchLabels:
      app: zhizhi-backend
  template:
    metadata:
      labels:
        app: zhizhi-backend
    spec:
      containers:
        - name: backend
          image: my-registry/zhizhi-backend:1.0.0
          ports:
            - containerPort: 8080
          env:
            - name: SPRING_PROFILES_ACTIVE
              value: prod
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "1000m"
              memory: "1Gi"
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8080
            initialDelaySeconds: 30
```

Service YAML：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: zhizhi-backend-svc
spec:
  selector:
    app: zhizhi-backend
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP
```

## kubectl 常用命令

```bash
# 查看资源
kubectl get pods -n production          # 查看 Pod 列表
kubectl get svc                         # 查看 Service
kubectl describe pod <name>             # 详细信息（排查问题首选）
kubectl logs -f <pod-name>              # 实时日志

# 部署操作
kubectl apply -f deployment.yaml        # 应用配置
kubectl rollout status deployment/xxx   # 查看滚动更新状态
kubectl rollout undo deployment/xxx     # 回滚到上一版本
kubectl scale deployment/xxx --replicas=5  # 手动扩容

# 调试
kubectl exec -it <pod-name> -- sh       # 进入 Pod
kubectl port-forward <pod-name> 8080:8080  # 本地端口转发
```

## 滚动更新策略

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1          # 更新时最多多出 1 个 Pod
    maxUnavailable: 0    # 更新时不允许有不可用的 Pod（零停机）
```',
'Kubernetes 入门完整指南：核心资源对比（Pod/Deployment/Service/ConfigMap）、Spring Boot 应用的 Deployment YAML 配置（含健康检查和资源限制）、kubectl 常用命令速查，以及零停机滚动更新策略配置。', 15, 1, 0),

(18, 'Spring Cloud Gateway 网关配置实践',
'# Spring Cloud Gateway 网关配置实践

## 为什么需要 API 网关？

微服务架构中，客户端直接调用各个微服务会导致：
- 客户端需要知道所有服务地址（耦合）
- 每个服务都要重复实现鉴权、日志、限流
- 跨域（CORS）配置分散

API 网关统一解决这些问题，是微服务的**南北向流量入口**。

## 引入依赖

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway</artifactId>
</dependency>
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
</dependency>
```

注意：Gateway 基于 WebFlux，**不能同时引入** spring-boot-starter-web。

## 路由配置

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: knowledge-service
          uri: lb://knowledge-service     # lb:// 表示负载均衡到注册中心的服务
          predicates:
            - Path=/api/knowledge/**
          filters:
            - StripPrefix=0              # 不裁切路径前缀

        - id: user-service
          uri: lb://user-service
          predicates:
            - Path=/api/users/**
            - Method=GET,POST
          filters:
            - AddRequestHeader=X-Gateway-Source, gateway  # 添加请求头
```

## 全局过滤器（JWT 鉴权）

```java
@Component
@Order(-100)                            // 最高优先级
public class AuthGlobalFilter implements GlobalFilter {

    private static final List<String> WHITE_LIST = List.of(
        "/api/auth/login", "/api/auth/register"
    );

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getURI().getPath();

        // 白名单直接放行
        if (WHITE_LIST.stream().anyMatch(path::startsWith)) {
            return chain.filter(exchange);
        }

        String token = exchange.getRequest().getHeaders()
            .getFirst(HttpHeaders.AUTHORIZATION);

        if (token == null || !token.startsWith("Bearer ")) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }

        // 解析 Token，将 userId 传递给下游服务
        Long userId = jwtUtil.getUserId(token.substring(7));
        ServerWebExchange mutated = exchange.mutate()
            .request(r -> r.header("X-User-Id", userId.toString()))
            .build();

        return chain.filter(mutated);
    }
}
```

## 请求限流（Redis + 令牌桶）

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: ai-service
          uri: lb://ai-service
          predicates:
            - Path=/api/ai/**
          filters:
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 10    # 每秒补充 10 个令牌
                redis-rate-limiter.burstCapacity: 20    # 令牌桶最大容量
                key-resolver: "#{@userKeyResolver}"     # 按用户限流
```

```java
@Bean
public KeyResolver userKeyResolver() {
    return exchange -> Mono.justOrEmpty(
        exchange.getRequest().getHeaders().getFirst("X-User-Id")
    );
}
```

## 跨域（CORS）全局配置

```yaml
spring:
  cloud:
    gateway:
      globalcors:
        cors-configurations:
          "[/**]":
            allowedOriginPatterns: "*"
            allowedMethods: [GET, POST, PUT, DELETE, OPTIONS]
            allowedHeaders: "*"
            allowCredentials: true
            maxAge: 3600
```',
'Spring Cloud Gateway 网关完整实践：路由配置（含负载均衡 lb://）、GlobalFilter 实现 JWT 鉴权并传递用户信息、Redis 令牌桶请求限流配置，以及全局 CORS 跨域解决方案。', 17, 1, 0);

-- ================================================================
-- 新增知识-标签关联
-- ================================================================
INSERT IGNORE INTO `knowledge_tag` (`knowledge_id`, `tag_id`) VALUES
(9,  15), (9,  12),                    -- Docker：Docker、后端开发
(10, 17), (10,  1), (10, 12),          -- Spring Cloud：Spring Cloud、Java、后端开发
(11, 18), (11, 19), (11, 12),          -- FastAPI：Python、FastAPI、后端开发
(12, 24), (12,  5), (12, 12),          -- Elasticsearch：Elasticsearch、MySQL、后端开发
(13, 20),                              -- Git：Git
(14, 21), (14,  8),                    -- Prompt工程：Prompt工程、LLM
(15, 22), (15,  8), (15,  7),          -- AI Agent：AI Agent、LLM、RAG
(16, 23), (16, 13), (16,  4),          -- TypeScript：TypeScript、前端开发、Vue3
(17, 16), (17, 15),                    -- Kubernetes：Kubernetes、Docker
(18, 17), (18,  1), (18,  2);          -- Spring Cloud Gateway：Spring Cloud、Java、Spring Boot

