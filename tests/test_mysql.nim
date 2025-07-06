import ../src/xorm/xorm

type User = object
  id: int
  name: string
  email: string

proc testMySQL() =
  echo "=== MySQL 连接测试 ==="
  
  # 创建 MySQL 会话
  let session = newDBSession(MySQL, "mysql://root:root123@127.0.0.1:3307/test")
  
  # 测试数据库连接
  echo "正在连接 MySQL..."
  if session.connect():
    echo "✅ MySQL 连接成功！"
    
    # 测试查询
    let allUsers = session.query(User).list()
    echo "查询所有用户: ", allUsers.len, " 条记录"
    
    # 测试条件查询
    let found = session.query(User).where("name = ?", "Alice").list()
    echo "查找 Alice: ", found.len, " 条记录"
    
    # 测试 SQL 生成
    let query = session.query(User).where("id > ?", "0").orderBy("name").limit(10)
    let (sql, params) = query.buildSql()
    echo "生成的 SQL: ", sql
    echo "参数: ", params
    
    session.disconnect()
    echo "✅ MySQL 连接已断开"
  else:
    echo "❌ MySQL 连接失败！"
    echo "（请确保 MySQL 服务已启动，且连接参数正确）"
  
  echo "✅ MySQL 测试完成"

when isMainModule:
  testMySQL() 