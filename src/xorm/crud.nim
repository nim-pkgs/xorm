## XORM - CRUD 操作模块（MySQL 版本）

import std/[strformat, strutils]
from typeinfo import Any, toAny, kind, getString, getBiggestInt, getBiggestFloat, getBool, fields, AnyKind
import ./core
import ./database

# ========== CRUD 操作 ==========

# 插入实体，返回自增主键或受影响行数
proc dbInsert*[T](session: DBSession, entity: T): int =
  let mapper = getOrCreateMapper[T](session)
  let tableName = mapper.tableInfo.name
  
  # 构建字段列表和值列表
  var fieldNames: seq[string]
  var placeholders: seq[string]
  var values: seq[string]
  
  # 获取实体的字段值
  var obj = entity
  let anyObj = toAny(obj)
  
  for field in fields(anyObj):
    let fieldName = field.name
    # 跳过自增主键
    if fieldName == "id" and mapper.tableInfo.primaryKey == "id":
      continue
    
    fieldNames.add(fieldName)
    placeholders.add("?")
    
    # 转换字段值为字符串
    case kind(field.any)
    of akString:
      values.add(getString(field.any))
    of akInt, akInt8, akInt16, akInt32, akInt64:
      values.add($getBiggestInt(field.any))
    of akFloat, akFloat32, akFloat64:
      values.add($getBiggestFloat(field.any))
    of akBool:
      values.add($getBool(field.any))
    else:
      values.add($field.any)
  
  # 构建 INSERT SQL
  let fieldNamesStr = fieldNames.join(", ")
  let placeholdersStr = placeholders.join(", ")
  let sql = fmt"INSERT INTO {tableName} ({fieldNamesStr}) VALUES ({placeholdersStr})"
  
  echo "执行 INSERT: ", sql
  echo "参数: ", values
  
  # 执行插入
  let resultSet = session.execute(sql, values)
  
  # 返回受影响的行数或最后插入的ID
  result = resultSet.affectedRows
  if resultSet.lastInsertId > 0:
    result = resultSet.lastInsertId

# 更新实体，根据主键更新
proc dbUpdate*[T](session: DBSession, entity: T): bool =
  let mapper = getOrCreateMapper[T](session)
  let tableName = mapper.tableInfo.name
  let primaryKey = mapper.tableInfo.primaryKey
  
  # 构建 SET 子句
  var setClauses: seq[string]
  var values: seq[string]
  var primaryKeyValue: string
  
  # 获取实体的字段值
  var obj = entity
  let anyObj = toAny(obj)
  
  for field in fields(anyObj):
    let fieldName = field.name
    let fieldValue = case kind(field.any)
      of akString: getString(field.any)
      of akInt, akInt8, akInt16, akInt32, akInt64: $getBiggestInt(field.any)
      of akFloat, akFloat32, akFloat64: $getBiggestFloat(field.any)
      of akBool: $getBool(field.any)
      else: $field.any
    
    if fieldName == primaryKey:
      primaryKeyValue = fieldValue
    else:
      setClauses.add(fmt"{fieldName} = ?")
      values.add(fieldValue)
  
  # 添加主键值到参数列表
  values.add(primaryKeyValue)
  
  # 构建 UPDATE SQL
  let setClausesStr = setClauses.join(", ")
  let sql = fmt"UPDATE {tableName} SET {setClausesStr} WHERE {primaryKey} = ?"
  
  echo "执行 UPDATE: ", sql
  echo "参数: ", values
  
  # 执行更新
  let resultSet = session.execute(sql, values)
  
  # 检查是否成功（返回受影响的行数 > 0）
  result = resultSet.affectedRows > 0

# 根据主键删除实体
proc dbDelete*[T](session: DBSession, id: int): bool =
  let mapper = getOrCreateMapper[T](session)
  let tableName = mapper.tableInfo.name
  let primaryKey = mapper.tableInfo.primaryKey
  
  # 构建 DELETE SQL
  let sql = fmt"DELETE FROM {tableName} WHERE {primaryKey} = ?"
  let values = @[$id]
  
  echo "执行 DELETE: ", sql
  echo "参数: ", values
  
  # 执行删除
  let resultSet = session.execute(sql, values)
  
  # 检查是否成功（返回受影响的行数 > 0）
  result = resultSet.affectedRows > 0

# 根据主键获取单个实体
proc dbGet*[T](session: DBSession, id: int): T =
  let mapper = getOrCreateMapper[T](session)
  let tableName = mapper.tableInfo.name
  let primaryKey = mapper.tableInfo.primaryKey
  
  # 构建 SELECT SQL
  let sql = fmt"SELECT * FROM {tableName} WHERE {primaryKey} = ?"
  let values = @[$id]
  
  echo "执行 GET: ", sql
  echo "参数: ", values
  
  # 执行查询
  let resultSet = session.execute(sql, values)
  
  # 映射结果到对象
  if resultSet.rows.len > 0:
    let row = resultSet.rows[0]
    if row.len >= 3:  # 确保有足够的列
      # 这里简化处理，假设字段顺序是 id, name, email
      result.id = parseInt(row[0])
      result.name = row[1]
      result.email = row[2]
    else:
      raise newException(ValueError, "Invalid row data")
  else:
    raise newException(ValueError, "No entity found with id: " & $id)

# ========== 导出功能 ==========

export dbInsert, dbUpdate, dbDelete, dbGet

# ========== 便利的模板别名 ==========

# 安全的模板别名，避免命名冲突
template xinsert*[T](session: DBSession, entity: T): int =
  dbInsert(session, entity)

template xupdate*[T](session: DBSession, entity: T): bool =
  dbUpdate(session, entity)

template xdelete*[T](session: DBSession, id: int): bool =
  dbDelete[T](session, id)

template xget*[T](session: DBSession, id: int): T =
  dbGet[T](session, id)

# 更简洁的版本（如果不怕和标准库冲突）
template save*[T](session: DBSession, entity: T): int =
  dbInsert(session, entity)

template find*[T](session: DBSession, id: int): T =
  dbGet[T](session, id)

template remove*[T](session: DBSession, id: int): bool =
  dbDelete[T](session, id) 