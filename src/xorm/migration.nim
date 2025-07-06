## XORM - 数据库迁移系统

import std/[strformat, strutils, tables]
import annotations
import core
import modelmacro

# ========== 迁移功能 ==========

proc generateCreateTableSQL*(meta: ModelMeta): string =
  ## 生成 CREATE TABLE SQL 语句
  var sql = fmt"CREATE TABLE IF NOT EXISTS {meta.name} ("
  var fieldDefs: seq[string]
  var constraints: seq[string]
  
  for field in meta.fields:
    if field.isIgnored: continue
    
    var fieldDef = fmt"{field.columnName} {field.dbType}"
    
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
      let fkConstraint = fmt"CONSTRAINT fk_{meta.name}_{field.name} FOREIGN KEY ({field.columnName}) REFERENCES {field.foreignTable}(id)"
      constraints.add(fkConstraint)
  
  # 合并字段定义和约束
  sql &= fieldDefs.join(", ")
  if constraints.len > 0:
    sql &= ", " & constraints.join(", ")
  sql &= ")"
  
  result = sql

proc generateDropTableSQL*(tableName: string): string =
  ## 生成 DROP TABLE SQL 语句
  fmt"DROP TABLE IF EXISTS {tableName}"

proc generateCreateIndexSQL(meta: ModelMeta): seq[string] =
  var stmts: seq[string]
  for field in meta.fields:
    if field.isIndexed:
      let indexName = if field.indexName.len > 0: field.indexName else: fmt"idx_{meta.name}_{field.columnName}"
      let indexDef = fmt"CREATE INDEX IF NOT EXISTS {indexName} ON {meta.name}({field.columnName})"
      stmts.add(indexDef)
  result = stmts

proc createTable*[T](session: DBSession): bool =
  ## 创建表
  if not isModelRegistered[T]():
    raise newException(ValueError, "Model not registered: " & $T)
  
  let meta = getModelMeta[T]()
  let sql = generateCreateTableSQL(meta)
  let indexSQLs = generateCreateIndexSQL(meta)
  try:
    discard session.execute(sql, @[])
    for idxSql in indexSQLs:
      discard session.execute(idxSql, @[])
    result = true
  except Exception as e:
    echo "建表失败: ", e.msg
    result = false

proc createTable*(session: DBSession, typeName: string): bool =
  ## 根据类型名创建表
  if not isModelRegistered(typeName):
    raise newException(ValueError, "Model not registered: " & typeName)
  
  let meta = getModelMeta(typeName)
  let sql = generateCreateTableSQL(meta)
  let indexSQLs = generateCreateIndexSQL(meta)
  try:
    discard session.execute(sql, @[])
    for idxSql in indexSQLs:
      discard session.execute(idxSql, @[])
    result = true
  except Exception as e:
    echo "建表失败: ", e.msg
    result = false

proc dropTable*[T](session: DBSession): bool =
  ## 删除表
  if not isModelRegistered[T]():
    raise newException(ValueError, "Model not registered: " & $T)
  
  let meta = getModelMeta[T]()
  let sql = generateDropTableSQL(meta.name)
  
  try:
    discard session.execute(sql, @[])
    result = true
  except:
    result = false

proc dropTable*(session: DBSession, tableName: string): bool =
  ## 根据表名删除表
  let sql = generateDropTableSQL(tableName)
  
  try:
    discard session.execute(sql, @[])
    result = true
  except:
    result = false

proc createAllTables*(session: DBSession): bool =
  ## 创建所有已注册模型对应的表
  var success = true
  
  for typeName, meta in pairs(runtimeModelRegistry):
    try:
      let sql = generateCreateTableSQL(meta)
      let indexSQLs = generateCreateIndexSQL(meta)
      discard session.execute(sql, @[])
      for idxSql in indexSQLs:
        discard session.execute(idxSql, @[])
      echo fmt"Created table: {meta.name}"
    except:
      echo fmt"Failed to create table: {meta.name}"
      success = false
  
  result = success

proc dropAllTables*(session: DBSession): bool =
  ## 删除所有已注册模型对应的表
  var success = true
  
  for typeName, meta in pairs(runtimeModelRegistry):
    try:
      let sql = generateDropTableSQL(meta.name)
      discard session.execute(sql, @[])
      echo fmt"Dropped table: {meta.name}"
    except:
      echo fmt"Failed to drop table: {meta.name}"
      success = false
  
  result = success

# ========== 导出功能 ==========
export generateCreateTableSQL, generateDropTableSQL
export createTable, dropTable, createAllTables, dropAllTables 