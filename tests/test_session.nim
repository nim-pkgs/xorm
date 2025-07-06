import ../src/xorm/xorm

type User = object
  id: int
  name: string
  email: string

proc testSession() =
  echo "=== 会话测试 ==="
  
  let session = newDBSession(SQLite, "sqlite://test_session.db")
  
  # 测试数据库连接
  echo "正在连接数据库..."
  if session.connect():
    echo "✅ 数据库连接成功！"
    
    # 测试查询所有
    let allUsers = session.query(User).list()
    echo "所有用户: ", allUsers.len, " 条记录"
    
    # 测试条件查询
    let found = session.query(User).where("name = ?", "Alice").list()
    echo "查找 Alice: ", found.len, " 条记录"
    
    # 测试单个查询
    let user = session.query(User).where("id = ?", "1").unique()
    echo "ID=1的用户: ", user.name
    
    # 测试断开连接
    session.disconnect()
    echo "✅ 数据库连接已断开"
  else:
    echo "❌ 数据库连接失败！"
  
  echo "✅ 会话测试完成"

when isMainModule:
  testSession() 