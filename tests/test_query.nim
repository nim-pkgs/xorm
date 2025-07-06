import ../src/xorm/xorm

type User = object
  id: int
  name: string
  email: string

proc testQuery() =
  echo "=== 查询测试 ==="
  
  # 创建数据库会话
  let session = newDBSession(SQLite, "sqlite://test_query.db")
  if not session.connect():
    echo "❌ 数据库连接失败"
    return
  
  echo "✅ 数据库连接成功"
  
  # 创建表并插入测试数据
  discard session.execute("""
    CREATE TABLE IF NOT EXISTS user (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name VARCHAR(255) NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL
    )
  """, @[])
  
  discard session.execute("DELETE FROM user", @[])
  discard session.execute("INSERT INTO user (name, email) VALUES (?, ?)", @["Alice", "alice@example.com"])
  discard session.execute("INSERT INTO user (name, email) VALUES (?, ?)", @["Bob", "bob@example.com"])
  
  # 测试链式查询
  let users = session.query(User)
    .where("name LIKE ?", "%Alice%")
    .orderBy("name")
    .list()
  
  echo "✅ 查询到 ", users.len, " 个用户"
  for user in users:
    echo "  - ", user.name, " (", user.email, ")"
  
  # 测试单个查询
  let user = session.query(User)
    .where("name = ?", "Bob")
    .unique()
  
  echo "✅ 查询单个用户: ", user.name
  
  # 断开连接
  session.disconnect()
  echo "✅ 查询测试完成"

when isMainModule:
  testQuery() 