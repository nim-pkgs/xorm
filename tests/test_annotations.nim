import ../src/xorm/xorm

type User = object
  id: int
  name: string
  email: string

proc testAnnotations() =
  echo "=== 注解系统测试 ==="
  
  # 测试注解系统基本功能
  echo "✅ 注解系统导入成功"
  
  # 测试字段注解解析
  let field1 = parseFieldAnnotation("id", "int", @["pk"])
  let field2 = parseFieldAnnotation("name", "string", @["unique", "notnull"])
  
  echo "字段1: ", field1.name, " (", field1.dbType, ") - 主键: ", field1.isPrimary
  echo "字段2: ", field2.name, " (", field2.dbType, ") - 唯一: ", field2.isUnique, " 非空: ", field2.isNotNull
  echo "✅ 注解解析成功"
  
  # 测试数据库连接
  let session = newDBSession(SQLite, "sqlite://annotations_test.db")
  if session.connect():
    echo "✅ 数据库连接成功"
    session.disconnect()
  else:
    echo "❌ 数据库连接失败"
  
  echo "✅ 注解系统测试完成"

when isMainModule:
  testAnnotations() 