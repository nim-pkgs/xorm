## XORM - 字段注解系统（简化版）

import std/[strutils, strformat, macros]

## 注解类型和常用 pragma 模板（全局共享）

# ========== 注解类型定义 ==========
type
  FieldAnnotation* = object
    name*: string
    typ*: string
    dbType*: string
    isPrimary*: bool
    isAutoIncrement*: bool
    isUnique*: bool
    isNotNull*: bool
    defaultValue*: string
    foreignKey*: string
    foreignTable*: string
    indexName*: string
    isIndexed*: bool
    columnName*: string
    isIgnored*: bool

  ModelMeta* = object
    name*: string
    fields*: seq[FieldAnnotation]

  TableAnnotation* = object
    name*: string
    fields*: seq[FieldAnnotation]

# ========== 常用注解 pragma ==========
template pk*(autoIncrement: bool = true) {.pragma.}
template fk*(table: typedesc) {.pragma.}
template unique*() {.pragma.}
template notnull*() {.pragma.}
template default*(value: string) {.pragma.}
template index*(name: string = "") {.pragma.}
template column*(name: string) {.pragma.}
template ignore*() {.pragma.}

# ========== 注解宏（简化版） ==========

# 主键注解
macro pk*(autoIncrement: bool = true): untyped =
  result = quote do:
    {.pragma: primaryKey, autoIncrement: `autoIncrement`.}

# 外键注解
macro fk*(table: string, column: string = "id"): untyped =
  result = quote do:
    {.pragma: foreignKey, table: `table`, column: `column`.}

# 唯一约束注解
macro unique*(): untyped =
  result = quote do:
    {.pragma: unique.}

# 非空约束注解
macro notnull*(): untyped =
  result = quote do:
    {.pragma: notnull.}

# 默认值注解
macro default*(value: string): untyped =
  result = quote do:
    {.pragma: default, value: `value`.}

# 索引注解
macro index*(name: string = ""): untyped =
  result = quote do:
    {.pragma: index, name: `name`.}

# 列注解
macro column*(name: string = "", dbType: string = ""): untyped =
  result = quote do:
    {.pragma: column, name: `name`, dbType: `dbType`.}

# ========== 注解解析器（简化版） ==========

# 解析字段注解（简化版）
proc parseFieldAnnotation*(fieldName: string, fieldType: string, pragmas: openArray[string]): FieldAnnotation =
  result = FieldAnnotation(
    name: fieldName,
    typ: fieldType,
    dbType: "",
    isPrimary: false,
    isAutoIncrement: false,
    isUnique: false,
    isNotNull: false,
    defaultValue: "",
    foreignKey: "",
    foreignTable: "",
    indexName: "",
    isIndexed: false,
    columnName: fieldName,
    isIgnored: false
  )
  
  # 根据 Nim 类型推断数据库类型
  case fieldType
  of "int", "int32": result.dbType = "INTEGER"
  of "int64": result.dbType = "BIGINT"
  of "string": result.dbType = "VARCHAR(255)"
  of "float", "float64": result.dbType = "REAL"
  of "bool": result.dbType = "BOOLEAN"
  else: result.dbType = "TEXT"
  
  # 解析注解
  for pragma in pragmas:
    case pragma
    of "pk", "primaryKey":
      result.isPrimary = true
      result.isAutoIncrement = true
    of "unique":
      result.isUnique = true
    of "notnull":
      result.isNotNull = true
    of "index":
      result.isIndexed = true
      result.indexName = "idx_" & fieldName
    else:
      if pragma.startsWith("fk:"):
        result.foreignKey = pragma[3..^1]
        result.foreignTable = pragma[3..^1]
      elif pragma.startsWith("default:"):
        result.defaultValue = pragma[8..^1]
      elif pragma.startsWith("column:"):
        let parts = pragma[7..^1].split(",")
        if parts.len > 0:
          result.name = parts[0].strip()
        if parts.len > 1:
          result.dbType = parts[1].strip()

# ========== SQL 生成器 ==========

# 生成 CREATE TABLE SQL
proc generateCreateTableSQL*(tableName: string, fields: seq[FieldAnnotation]): string =
  var sql = fmt"CREATE TABLE IF NOT EXISTS {tableName} (\n"
  var fieldDefs: seq[string]
  var constraints: seq[string]
  
  for field in fields:
    var fieldDef = fmt"  {field.name} {field.dbType}"
    
    # 主键
    if field.isPrimary:
      fieldDef &= " PRIMARY KEY"
      if field.isAutoIncrement:
        fieldDef &= " AUTOINCREMENT"
    
    # 非空约束
    if field.isNotNull:
      fieldDef &= " NOT NULL"
    
    # 唯一约束
    if field.isUnique:
      fieldDef &= " UNIQUE"
    
    # 默认值
    if field.defaultValue.len > 0:
      fieldDef &= fmt" DEFAULT {field.defaultValue}"
    
    fieldDefs.add(fieldDef)
    
    # 外键约束
    if field.foreignKey.len > 0:
      let fkConstraint = fmt"  CONSTRAINT fk_{tableName}_{field.name} FOREIGN KEY ({field.name}) REFERENCES {field.foreignTable}(id)"
      constraints.add(fkConstraint)
    
    # 索引
    if field.isIndexed:
      let indexName = if field.indexName.len > 0: field.indexName else: fmt"idx_{tableName}_{field.name}"
      let indexDef = fmt"  CREATE INDEX {indexName} ON {tableName}({field.name})"
      constraints.add(indexDef)
  
  # 合并字段定义和约束
  sql &= fieldDefs.join(",\n")
  if constraints.len > 0:
    sql &= ",\n" & constraints.join(",\n")
  sql &= "\n)"
  
  result = sql

# ========== 便利函数 ==========

# 创建带注解的字段定义
proc createField*(name: string, fieldType: string, annotations: varargs[string]): FieldAnnotation =
  result = parseFieldAnnotation(name, fieldType, annotations)

# 创建表定义
proc createTable*(name: string, fields: varargs[FieldAnnotation]): TableAnnotation =
  result = TableAnnotation(name: name, fields: @[])
  for field in fields:
    result.fields.add(field)

# ========== 导出功能 ==========

export FieldAnnotation, TableAnnotation
export pk, fk, unique, notnull, default, index, column
export parseFieldAnnotation, generateCreateTableSQL
export createField, createTable 