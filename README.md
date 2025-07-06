# XORM - A Simple ORM Framework for Nim

一个简单 Nim ORM 框架。

## 特性

- 🚀 **极简 API**：用户只需定义类型，`session.query(User)` 自动处理一切
- 🔄 **自动反射**：运行时自动分析对象字段，生成数据库映射
- 💾 **智能缓存**：自动缓存映射器，避免重复生成
- 🛡️ **类型安全**：完整的类型检查和 IDE 支持
- 🎯 **Go 风格**：简洁的 API 设计，类似 Go 的 GORM

## 快速开始

### 1. 定义实体类型

```nim
type
  User = object
    id: int
    name: string
    email: string
    age: int
```

### 2. 创建会话并查询

```nim
import xorm

let session = newDBSession(SQLite, "sqlite://test.db")

# 自动生成映射器并执行查询
let users = session.query(User)
  .where("age > ?", 18)
  .orderBy("name")
  .limit(10)
  .list()

echo "找到用户: ", users.len
```

## 已实现功能 ✅

### 核心架构
- [x] **类型定义系统**
  - `DatabaseType` - 支持 SQLite, PostgreSQL, MySQL
  - `FieldInfo` - 字段信息（名称、类型、约束）
  - `TableInfo` - 表信息（名称、字段、主键）
  - `MapperBase` - 基础映射器接口
  - `Mapper[T]` - 泛型映射器
  - `QueryBuilder[T]` - 查询构建器
  - `DBSession` - 数据库会话

### 自动映射系统
- [x] **运行时反射**
  - 自动分析对象字段结构
  - 智能推断数据库字段类型
  - 自动处理主键和自增字段
- [x] **映射器缓存**
  - 首次查询时自动生成映射器
  - 后续查询直接使用缓存
  - 支持多实体类型独立缓存

### 数据库连接层
- [x] **SQLite 连接**
  - 完整的连接管理
  - 事务支持
  - 查询执行
- [x] **PostgreSQL 连接**
  - 连接字符串解析
  - 事务支持
  - 查询执行
- [x] **MySQL 连接**
  - 连接字符串解析
  - 事务支持
  - 查询执行

### 查询构建器
- [x] **基础查询**
  - `session.query(User)` - 自动查找/生成映射器
  - `buildSql()` - 生成 SQL 语句
  - `list()` - 执行查询并返回真实数据
- [x] **查询条件**
  - `where(clause, params...)` - WHERE 条件
  - `orderBy(field)` - 排序
  - `limit(count)` - 限制结果数量
  - `offset(count)` - 分页偏移
- [x] **结果处理**
  - `unique()` - 获取单个结果
  - `first()` - 获取第一个结果
- [x] **字段选择**
  - `selectFields` - 支持选择特定字段
  - 自动生成 SELECT 语句

### CRUD 操作
- [x] **插入操作**
  - `dbInsert(session, entity)` - 插入实体
  - `xinsert(session, entity)` - 便捷别名
  - 返回自增主键或受影响行数
- [x] **更新操作**
  - `dbUpdate(session, entity)` - 根据主键更新
  - `xupdate(session, entity)` - 便捷别名
- [x] **删除操作**
  - `dbDelete(session, id)` - 根据主键删除
  - `xdelete(session, id)` - 便捷别名
- [x] **查询操作**
  - `dbGet(session, id)` - 根据主键获取单个实体
  - `xget(session, id)` - 便捷别名

### 事务支持
- [x] **事务管理**
  - `beginTransaction()` - 开始事务
  - `commit()` - 提交事务
  - `rollback()` - 回滚事务
  - `withTransaction()` - 事务块模板

### 字段注解系统
- [x] **注解支持**
  - `{.pk.}` - 主键注解
  - `{.unique.}` - 唯一约束
  - `{.notnull.}` - 非空约束
  - `{.default: "value".}` - 默认值
  - `{.index.}` - 索引注解
  - `{.column: "name".}` - 列名映射
  - `{.ignore.}` - 忽略字段
  - `{.fk: Table.}` - 外键注解
- [x] **注解解析**
  - 编译时注解解析
  - 运行时注解处理
  - 自动生成 CREATE TABLE SQL

### 模型注册系统
- [x] **模型注册**
  - `registerModel(User)` - 注册模型
  - 编译时元数据收集
  - 运行时模型元数据访问
  - `getModelMeta()` - 获取模型元数据
  - `isModelRegistered()` - 检查模型注册状态

### 数据库迁移
- [x] **迁移功能**
  - `createTable(session, User)` - 创建表
  - `dropTable(session, User)` - 删除表
  - `createAllTables(session)` - 创建所有表
  - `dropAllTables(session)` - 删除所有表
  - `generateCreateTableSQL()` - 生成建表 SQL
  - `generateDropTableSQL()` - 生成删表 SQL

### 连接池
- [x] **连接池管理**
  - `ConnectionPool` - 连接池实现
  - `PooledDBSession` - 支持连接池的会话
  - 连接健康检查
  - 自动连接管理
  - 连接统计信息
  - `withConnection()` - 自动连接管理模板
  - `cleanupIdleConnections()` - 清理空闲连接

### 聚合查询（基础实现）
- [x] **基础聚合**
  - 通过 `list().len` 实现计数查询
  - 支持条件聚合（如活跃用户数）
  - 可扩展的聚合框架

### 内存管理
- [x] **ARC/ORC 兼容**
  - 正确处理 Nim 的内存管理
  - 避免泛型类型析构问题
  - 稳定的对象生命周期

### 测试覆盖
- [x] **完整测试套件**
  - 查询测试 (`test_query.nim`)
  - CRUD 测试 (`test_crud.nim`)
  - 迁移测试 (`test_migration.nim`)
  - 模型注册测试 (`test_model_registration.nim`)
  - 注解测试 (`test_annotations.nim`)
  - 连接池测试 (`test_connection_pool.nim`)
  - 完整功能演示 (`complete_example.nim`)

## 缺乏的功能 🔴

### 高优先级功能

#### 1. 高级聚合查询
```nim
# 原生聚合函数
proc count*[T](queryBuilder: QueryBuilder[T]): int
proc sum*[T](queryBuilder: QueryBuilder[T], field: string): float
proc avg*[T](queryBuilder: QueryBuilder[T], field: string): float
proc max*[T](queryBuilder: QueryBuilder[T], field: string): float
proc min*[T](queryBuilder: QueryBuilder[T], field: string): float
```

**状态**: 部分实现（通过 list().len 实现计数）  
**影响**: 需要手动实现复杂聚合查询

#### 2. 关联查询
```nim
# 关联查询
proc join*[T, U](queryBuilder: QueryBuilder[T], other: typedesc[U], on: string): QueryBuilder[T]
proc leftJoin*[T, U](queryBuilder: QueryBuilder[T], other: typedesc[U], on: string): QueryBuilder[T]
proc rightJoin*[T, U](queryBuilder: QueryBuilder[T], other: typedesc[U], on: string): QueryBuilder[T]
```

**状态**: 未实现  
**影响**: 无法进行表关联查询

#### 3. 批量操作
```nim
# 批量插入
proc batchInsert*[T](session: DBSession, entities: seq[T]): seq[int]
# 批量更新
proc batchUpdate*[T](session: DBSession, entities: seq[T]): int
# 批量删除
proc batchDelete*[T](session: DBSession, ids: seq[int]): int
```

**状态**: 未实现  
**影响**: 大量数据操作性能受限

### 中优先级功能

#### 4. 查询优化
```nim
# 预加载关联
proc preload*[T](queryBuilder: QueryBuilder[T], relations: varargs[string]): QueryBuilder[T]
# 分组查询
proc groupBy*[T](queryBuilder: QueryBuilder[T], fields: varargs[string]): QueryBuilder[T]
# 子查询支持
proc subquery*[T](queryBuilder: QueryBuilder[T]): string
```

**状态**: 未实现  
**影响**: 查询性能优化受限

#### 5. 日志和调试系统
```nim
type LogLevel = enum
  Debug, Info, Warning, Error

proc enableLogging*(session: DBSession, level: LogLevel)
proc logQuery*(session: DBSession, sql: string, params: seq[string])
proc logError*(session: DBSession, error: string)
```

**状态**: 未实现  
**影响**: 调试困难，缺乏查询性能分析

#### 6. 查询缓存
```nim
# 查询结果缓存
proc enableQueryCache*(session: DBSession, ttl: Duration)
proc clearQueryCache*(session: DBSession)
proc getCachedResult*[T](queryBuilder: QueryBuilder[T]): Option[seq[T]]
```

**状态**: 未实现  
**影响**: 重复查询性能不佳

### 低优先级功能

#### 7. 数据库方言适配
```nim
# 不同数据库的 SQL 方言
proc generateSQLForSQLite*(queryBuilder: QueryBuilder[T]): string
proc generateSQLForPostgreSQL*(queryBuilder: QueryBuilder[T]): string
proc generateSQLForMySQL*(queryBuilder: QueryBuilder[T]): string
```

**状态**: 部分实现（基础查询）  
**影响**: 高级 SQL 功能可能不兼容

#### 8. 数据库版本管理
```nim
# 版本迁移
proc createMigration*(name: string): Migration
proc runMigration*(session: DBSession, migration: Migration): bool
proc rollbackMigration*(session: DBSession, version: int): bool
```

**状态**: 未实现  
**影响**: 数据库架构变更管理困难

#### 9. 性能监控
```nim
# 查询性能监控
proc enablePerformanceMonitoring*(session: DBSession)
proc getSlowQueries*(session: DBSession): seq[QueryStats]
proc getQueryStats*(session: DBSession): QueryStats
```

**状态**: 未实现  
**影响**: 无法监控和优化查询性能

## 项目结构

```
xorm/
├── src/xorm/
│   ├── core.nim           # 核心功能和类型定义
│   ├── database.nim       # 数据库连接层
│   ├── crud.nim          # CRUD 操作
│   ├── annotations.nim   # 字段注解系统
│   ├── modelmacro.nim    # 模型注册宏
│   ├── migration.nim     # 数据库迁移
│   ├── connectionpool.nim # 连接池管理
│   ├── pooled_session.nim # 连接池会话
│   └── xorm.nim          # 主入口文件
├── examples/
│   ├── complete_example.nim           # 完整功能演示
│   ├── model_registration_example.nim # 模型注册示例
│   ├── connection_pool_test.nim       # 连接池测试
│   └── simple_session_example.nim     # 基础会话示例
├── tests/
│   ├── test_query.nim              # 查询测试
│   ├── test_crud.nim               # CRUD 测试
│   ├── test_migration.nim          # 迁移测试
│   ├── test_model_registration.nim # 模型注册测试
│   ├── test_annotations.nim        # 注解测试
│   └── test_connection_pool.nim    # 连接池测试
└── README.md
```

## 开发路线图

### Phase 1: 基础功能 ✅ (已完成)
- [x] 实现 SQLite 连接
- [x] 实现 PostgreSQL 连接  
- [x] 实现 MySQL 连接
- [x] 基础查询执行
- [x] CRUD 操作
- [x] 事务支持
- [x] 字段注解系统
- [x] 数据库迁移
- [x] 连接池
- [x] 模型注册系统
- [x] 完整测试套件

### Phase 2: 高级查询功能 (进行中)
- [ ] 原生聚合查询 (count, sum, avg, max, min)
- [ ] 关联查询 (join, leftJoin, rightJoin)
- [ ] 分组查询 (groupBy, having)
- [ ] 子查询支持
- [ ] 查询优化 (preload, select)

### Phase 3: 性能优化 (计划中)
- [ ] 查询缓存系统
- [ ] 批量操作支持
- [ ] 查询性能监控
- [ ] 数据库方言适配
- [ ] 索引优化建议

### Phase 4: 生产就绪 (计划中)
- [ ] 完整的日志系统
- [ ] 数据库版本管理
- [ ] 分布式支持
- [ ] 性能基准测试
- [ ] 文档完善

## 使用示例

### 基础查询
```nim
import xorm

type User = object
  id: int
  name: string
  email: string

let session = newDBSession(SQLite, "sqlite://test.db")

# 查询所有用户
let allUsers = session.query(User).list()

# 条件查询
let activeUsers = session.query(User)
  .where("age > ?", 18)
  .orderBy("name")
  .limit(10)
  .list()

# 获取单个用户
let user = session.query(User)
  .where("id = ?", 1)
  .unique()
```

### CRUD 操作
```nim
# 插入用户
let newUser = User(name: "张三", email: "zhangsan@example.com")
let userId = session.xinsert(newUser)

# 更新用户
newUser.name = "李四"
let updated = session.xupdate(newUser)

# 获取用户
let user = session.xget(User, userId)

# 删除用户
let deleted = session.xdelete(User, userId)
```

### 带注解的模型
```nim
type User = object
  id {.pk.}: int
  name {.notnull, unique.}: string
  email {.unique, index.}: string
  age {.default: "18".}: int
  created_at {.column: "created_at".}: string
  temp_field {.ignore.}: bool

registerModel(User)

# 创建表
session.createTable(User)
```

### 事务操作
```nim
# 使用事务块
let success = session.withTransaction:
  let user1 = User(name: "用户1", email: "user1@example.com")
  let user2 = User(name: "用户2", email: "user2@example.com")
  
  session.xinsert(user1)
  session.xinsert(user2)
  
  # 如果任何操作失败，整个事务会回滚
```

### 连接池使用
```nim
# 创建连接池会话
let pooledSession = newPooledDBSession(SQLite, "sqlite://test.db")

# 使用连接池进行查询
let users = pooledSession.query(User).list()

# 获取连接池统计信息
let (total, available, inUse) = pooledSession.getPoolStats()
echo "连接池状态: 总数=", total, " 可用=", available, " 使用中=", inUse

# 清理空闲连接
pooledSession.cleanupIdleConnections()

# 关闭连接池
pooledSession.shutdown()
```

### 聚合查询（当前实现）
```nim
# 计数查询（通过 list().len 实现）
let userCount = session.query(User).list().len
echo "用户总数: ", userCount

let activeUserCount = session.query(User)
  .where("isActive = ?", "1")
  .list().len
echo "活跃用户数: ", activeUserCount
```

### 链式查询
```nim
let query = session.query(User)
  .where("status = ?", "active")
  .orderBy("created_at DESC")
  .limit(20)
  .offset(40)

let (sql, params) = query.buildSql()
echo "SQL: ", sql
echo "参数: ", params
```

### 模型元数据访问
```nim
# 检查模型注册状态
echo "User 已注册: ", isModelRegistered("User")

# 获取模型元数据
let userMeta = getModelMeta("User")
for field in userMeta.fields:
  echo "字段: ", field.name, " -> ", field.dbType

# 生成建表 SQL
let createTableSQL = generateCreateTableSQL(userMeta)
echo createTableSQL
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License 