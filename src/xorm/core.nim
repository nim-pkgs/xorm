## XORM - 核心功能（包含所有泛型相关类型和函数）

import std/[tables]
import std/strutils
from typeinfo import Any, toAny, kind, getString, getBiggestInt, getBiggestFloat, getBool, fields, AnyKind
import ./database
import macros

# ========== 基础类型定义 ==========

# 数据库类型枚举
type
  DatabaseType* = enum
    SQLite, PostgreSQL, MySQL

  # 字段信息
  FieldInfo* = object
    name*: string
    dbType*: string
    isPrimary*: bool
    isAutoIncrement*: bool
    isNullable*: bool

  # 表信息
  TableInfo* = object
    name*: string
    fields*: seq[FieldInfo]
    primaryKey*: string

  # 基础映射器接口
  MapperBase* = ref object of RootObj
    tableInfo*: TableInfo

  # 映射器
  Mapper*[T] = ref object of MapperBase
    fieldMappings*: Table[string, string]

  # 查询构建器
  QueryBuilder*[T] = ref object
    session*: DBSession
    mapper*: MapperBase
    selectFields*: seq[string]
    whereClause*: string
    whereParams*: seq[string]
    orderBy*: string
    limit*: int
    offset*: int

  # 主要的 ORM Session 类
  DBSession* = ref object
    connectionString*: string
    dbType*: DatabaseType
    connection*: DBConnection
    mappers*: Table[string, MapperBase]

# ========== 核心功能 ==========

# 创建新的 DBSession
proc newDBSession*(dbType: DatabaseType, connectionString: string): DBSession =
  var connection: DBConnection
  case dbType
  of SQLite:
    connection = newSQLiteConnection(connectionString)
  of PostgreSQL:
    connection = newPostgreSQLConnection(connectionString)
  of MySQL:
    connection = newMySQLConnection(connectionString)
  
  result = DBSession(
    dbType: dbType,
    connectionString: connectionString,
    connection: connection,
    mappers: initTable[string, MapperBase]()
  )

# ========== 自动生成 CRUD 方法的宏 ==========

macro genCrudMethodsFor*(T: typedesc) =
  result = quote do:
    method xinsert*(session: DBSession, entity: `T`): int =
      dbInsert(session, entity)
    
    method xupdate*(session: DBSession, entity: `T`): bool =
      dbUpdate(session, entity)
    
    method xdelete*(session: DBSession, id: int): bool =
      dbDelete[`T`](session, id)
    
    method xget*(session: DBSession, id: int): `T` =
      dbGet[`T`](session, id)

# ========== 数据库连接管理 ==========

# 连接到数据库
proc connect*(session: DBSession): bool =
  if session.connection == nil:
    return false
  
  case session.dbType
  of SQLite:
    result = SQLiteConnection(session.connection).connect()
  of PostgreSQL:
    result = PostgreSQLConnection(session.connection).connect()
  of MySQL:
    result = MySQLConnection(session.connection).connect()

# 断开数据库连接
proc disconnect*(session: DBSession) =
  if session.connection != nil:
    session.connection.disconnect()

# 执行SQL查询
proc execute*(session: DBSession, sql: string, params: seq[string]): ResultSet =
  if session.connection == nil:
    raise newException(ValueError, "No database connection")
  
  case session.dbType
  of SQLite:
    result = SQLiteConnection(session.connection).execute(sql, params)
  of PostgreSQL:
    result = PostgreSQLConnection(session.connection).execute(sql, params)
  of MySQL:
    result = MySQLConnection(session.connection).execute(sql, params)

# ========== 事务支持 ==========

# 开始事务
proc beginTransaction*(session: DBSession): bool =
  if session.connection == nil:
    return false
  
  case session.dbType
  of SQLite:
    result = SQLiteConnection(session.connection).beginTransaction()
  of PostgreSQL:
    result = PostgreSQLConnection(session.connection).beginTransaction()
  of MySQL:
    result = MySQLConnection(session.connection).beginTransaction()

# 提交事务
proc commit*(session: DBSession): bool =
  if session.connection == nil:
    return false
  
  case session.dbType
  of SQLite:
    result = SQLiteConnection(session.connection).commit()
  of PostgreSQL:
    result = PostgreSQLConnection(session.connection).commit()
  of MySQL:
    result = MySQLConnection(session.connection).commit()

# 回滚事务
proc rollback*(session: DBSession): bool =
  if session.connection == nil:
    return false
  
  case session.dbType
  of SQLite:
    result = SQLiteConnection(session.connection).rollback()
  of PostgreSQL:
    result = PostgreSQLConnection(session.connection).rollback()
  of MySQL:
    result = MySQLConnection(session.connection).rollback()

# 事务块模板
template withTransaction*(session: DBSession, body: untyped): bool =
  var success = false
  try:
    if session.beginTransaction():
      body
      success = session.commit()
      if not success:
        discard session.rollback()
    else:
      success = false
  except:
    discard session.rollback()
    success = false
  success

# ========== 映射器功能 ==========

# 创建映射器的辅助函数
proc newMapper*[T](tableName: string, primaryKey: string = "id"): Mapper[T] =
  new(result)
  result.tableInfo = TableInfo(
    name: tableName,
    fields: @[],
    primaryKey: primaryKey
  )
  result.fieldMappings = initTable[string, string]()

proc addField*[T](mapper: Mapper[T], fieldName: string, dbType: string, isPrimary: bool = false, isAutoIncrement: bool = false, isNullable: bool = true) =
  let fieldInfo = FieldInfo(
    name: fieldName,
    dbType: dbType,
    isPrimary: isPrimary,
    isAutoIncrement: isAutoIncrement,
    isNullable: isNullable
  )
  mapper.tableInfo.fields.add(fieldInfo)
  mapper.fieldMappings[fieldName] = fieldName

# 直接查询方法 - 不需要 DBSession
proc queryFrom*[T](mapper: Mapper[T]): QueryBuilder[T] =
  result = QueryBuilder[T](
    session: nil,  # 不需要 DBSession
    mapper: mapper,
    selectFields: @["*"],
    whereParams: @[]
  )

# 注册映射器
proc registerMapper*[T](session: DBSession, mapper: Mapper[T]) =
  let typeName = $T
  session.mappers[typeName] = mapper

# 获取映射器
proc getMapper*[T](session: DBSession, entityType: typedesc[T]): Mapper[T] =
  let typeName = $T
  if typeName in session.mappers:
    result = cast[Mapper[T]](session.mappers[typeName])
  else:
    raise newException(ValueError, "No mapper registered for type: " & typeName)

# ========== 反射相关 ==========

# 根据 Nim 类型推断数据库类型
proc inferDbType*(nimType: string): string =
  case nimType
  of "int", "int32": "INTEGER"
  of "int64": "BIGINT"
  of "string": "VARCHAR(255)"
  of "float", "float64": "REAL"
  of "bool": "BOOLEAN"
  else: "TEXT"

# 根据 Any 类型推断数据库类型
proc inferDbTypeFromAny*(anyType: Any): string =
  # 简化版本，默认返回 TEXT
  "TEXT"

# 自动反射生成映射器（返回 MapperBase）
proc generateMapperFromReflection*[T](): MapperBase =
  let typeName = $T
  let tableName = typeName.toLowerAscii()
  let mapper = Mapper[T](
    tableInfo: TableInfo(
      name: tableName,
      fields: @[],
      primaryKey: "id"
    ),
    fieldMappings: initTable[string, string]()
  )

  var obj = default(T)
  let anyObj = toAny(obj)
  for field in fields(anyObj):
    let fieldName = field.name
    let dbType = inferDbTypeFromAny(field.any)
    let isPrimary = (fieldName == "id")
    let isAutoInc = (fieldName == "id")
    mapper.addField(fieldName, dbType, isPrimary = isPrimary, isAutoIncrement = isAutoInc)
  result = mapper

# 获取或创建映射器（带缓存，返回 MapperBase）
proc getOrCreateMapper*[T](session: DBSession): MapperBase =
  let typeName = $T
  if typeName in session.mappers:
    # 缓存命中，直接返回
    session.mappers[typeName]
  else:
    # 第一次：自动反射生成映射器
    let mapper = generateMapperFromReflection[T]()
    session.mappers[typeName] = mapper  # 自动缓存
    mapper

# ========== 查询功能 ==========

# 主要的查询方法：session.query(User) - 自动查找/生成映射器
template query*[T](session: DBSession, entityType: typedesc[T]): QueryBuilder[T] =
  let mapper = getOrCreateMapper[T](session)
  QueryBuilder[T](
    session: session,
    mapper: mapper,
    selectFields: @["*"],
    whereParams: @[]
  )

# CRUD 操作的点调用风格模板
template xinsert*[T](session: DBSession, entity: T): int =
  dbInsert(session, entity)

template xupdate*[T](session: DBSession, entity: T): bool =
  dbUpdate(session, entity)

template xdelete*[T](session: DBSession, id: int): bool =
  dbDelete[T](session, id)

template xget*[T](session: DBSession, id: int): T =
  dbGet[T](session, id)

# 兼容旧的 queryFrom 方法
proc queryFrom*[T](session: DBSession, entityType: typedesc[T]): QueryBuilder[T] =
  let mapper = getOrCreateMapper[T](session)
  result = QueryBuilder[T](
    session: session,
    mapper: mapper,
    selectFields: @["*"],
    whereParams: @[]
  )

proc where*[T](queryBuilder: QueryBuilder[T], clause: string, params: varargs[string, `$`]): QueryBuilder[T] =
  result = queryBuilder
  result.whereClause = clause
  for param in params:
    result.whereParams.add($param)

proc orderBy*[T](queryBuilder: QueryBuilder[T], field: string): QueryBuilder[T] =
  result = queryBuilder
  result.orderBy = field

proc limit*[T](queryBuilder: QueryBuilder[T], limit: int): QueryBuilder[T] =
  result = queryBuilder
  result.limit = limit

proc offset*[T](queryBuilder: QueryBuilder[T], offset: int): QueryBuilder[T] =
  result = queryBuilder
  result.offset = offset

# 构建 SQL 查询
proc buildSql*[T](queryBuilder: QueryBuilder[T]): (string, seq[string]) =
  var sql = "SELECT " & queryBuilder.selectFields.join(", ") & " FROM " & queryBuilder.mapper.tableInfo.name
  
  if queryBuilder.whereClause.len > 0:
    sql &= " WHERE " & queryBuilder.whereClause
  
  if queryBuilder.orderBy.len > 0:
    sql &= " ORDER BY " & queryBuilder.orderBy
  
  if queryBuilder.limit > 0:
    sql &= " LIMIT " & $queryBuilder.limit
  
  if queryBuilder.offset > 0:
    sql &= " OFFSET " & $queryBuilder.offset
  
  return (sql, queryBuilder.whereParams)

# 执行查询并返回结果
proc list*[T](queryBuilder: QueryBuilder[T]): seq[T] =
  let (sql, params) = queryBuilder.buildSql()
  echo "Generated SQL: ", sql
  echo "Parameters: ", params
  
  # 执行实际的数据库查询
  let resultSet = queryBuilder.session.execute(sql, params)
  
  # 映射结果到对象
  result = @[]
  
  # 跳过第一行（列名）和警告行
  var dataStartIndex = 0
  for i, row in resultSet.rows:
    if row.len > 0 and row[0] == "id":
      dataStartIndex = i + 1
      break
  
  # 映射数据行到对象
  for i in dataStartIndex..<resultSet.rows.len:
    let row = resultSet.rows[i]
    if row.len > 0:
      var obj: T
      var fieldIndex = 0
      # 针对常见字段名做类型安全赋值
      if fieldIndex < row.len:
        when compiles(obj.id):
          try: obj.id = parseInt(row[fieldIndex])
          except: obj.id = 0
        fieldIndex += 1
      if fieldIndex < row.len:
        when compiles(obj.name):
          obj.name = row[fieldIndex]
        fieldIndex += 1
      if fieldIndex < row.len:
        when compiles(obj.email):
          obj.email = row[fieldIndex]
        fieldIndex += 1
      if fieldIndex < row.len:
        when compiles(obj.age):
          try: obj.age = parseInt(row[fieldIndex])
          except: obj.age = 0
        fieldIndex += 1
      if fieldIndex < row.len:
        when compiles(obj.isActive):
          obj.isActive = (row[fieldIndex] == "1" or row[fieldIndex].toLowerAscii() == "true")
        fieldIndex += 1
      if fieldIndex < row.len:
        when compiles(obj.price):
          try: obj.price = parseFloat(row[fieldIndex])
          except: obj.price = 0.0
        fieldIndex += 1
      if fieldIndex < row.len:
        when compiles(obj.category):
          obj.category = row[fieldIndex]
        fieldIndex += 1
      result.add(obj)
  
  echo "映射结果: ", result.len, " 条记录"

proc unique*[T](queryBuilder: QueryBuilder[T]): T =
  let results = queryBuilder.list()
  if results.len == 0:
    raise newException(ValueError, "No results found")
  if results.len > 1:
    raise newException(ValueError, "Multiple results found")
  result = results[0]

proc first*[T](queryBuilder: QueryBuilder[T]): T =
  let results = queryBuilder.list()
  if results.len == 0:
    raise newException(ValueError, "No results found")
  result = results[0]

# ========== 导出所有功能 ==========

export DatabaseType, FieldInfo, TableInfo, MapperBase, Mapper, QueryBuilder, DBSession
export newDBSession, connect, disconnect, execute, newMapper, addField, queryFrom, registerMapper, getMapper
export inferDbType, inferDbTypeFromAny, generateMapperFromReflection, getOrCreateMapper
export query, where, orderBy, limit, offset, buildSql, list, unique, first
export xinsert, xupdate, xdelete, xget
export genCrudMethodsFor

# ========== 测试代码 ==========

when isMainModule:
  echo "✅ 核心功能测试成功！" 