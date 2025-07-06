import ../src/xorm/xorm

type User = object
  id: int
  name: string
  email: string

proc testCRUD() =
  echo "=== CRUD 测试 ==="
  
  # 创建数据库会话
  let session = newDBSession(SQLite, "sqlite://test_crud.db")
  if not session.connect():
    echo "❌ 数据库连接失败"
    return
  
  echo "✅ 数据库连接成功"
  
  # 创建表
  discard session.execute("""
    CREATE TABLE IF NOT EXISTS user (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name VARCHAR(255) NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL
    )
  """, @[])
  
  # 测试插入
  let user = User(id: 0, name: "Alice", email: "alice@example.com")
  let userId = dbInsert(session, user)
  echo "✅ 插入用户成功，ID: ", userId
  
  # 测试查询
  let retrievedUser = dbGet[User](session, userId)
  echo "✅ 查询用户成功: ", retrievedUser.name
  
  # 测试更新
  var updatedUser = retrievedUser
  updatedUser.name = "Alice Updated"
  if dbUpdate(session, updatedUser):
    echo "✅ 更新用户成功"
  
  # 测试删除
  if dbDelete[User](session, userId):
    echo "✅ 删除用户成功"
  
  # 断开连接
  session.disconnect()
  echo "✅ CRUD 测试完成"

when isMainModule:
  testCRUD() 