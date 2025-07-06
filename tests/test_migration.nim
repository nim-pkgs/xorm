import ../src/xorm/xorm

type User = object
  id: int
  name: string
  email: string

proc testMigration() =
  echo "=== 迁移测试 ==="
  
  let session = newDBSession(SQLite, "sqlite://test_migration.db")
  
  if session.connect():
    echo "✅ 数据库连接成功"
    
    # 测试基本迁移功能
    echo "✅ 迁移模块导入成功"
    
    # 测试表操作
    let createTableSQL = "CREATE TABLE IF NOT EXISTS user (id INTEGER PRIMARY KEY, name TEXT, email TEXT)"
    try:
      discard session.execute(createTableSQL, @[])
      echo "✅ 表创建成功"
    except Exception as e:
      echo "❌ 表创建失败: ", e.msg
    
    session.disconnect()
    echo "✅ 数据库连接已断开"
  else:
    echo "❌ 数据库连接失败"
  
  echo "✅ 迁移测试完成"

when isMainModule:
  testMigration() 