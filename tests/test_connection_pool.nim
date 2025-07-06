import ../src/xorm/xorm

type User = object
  id: int
  name: string
  email: string

proc testConnectionPool() =
  echo "=== 连接池测试 ==="
  
  # 创建连接池
  let pool = newConnectionPool(SQLite, "sqlite://test_pool.db")
  echo "✅ 连接池创建成功"
  
  # 测试连接获取和释放
  let conn = getConnection(pool)
  echo "✅ 获取连接成功"
  
  releaseConnection(pool, conn)
  echo "✅ 释放连接成功"
  
  # 测试 withConnection 模板
  withConnection(pool, conn2):
    echo "✅ withConnection 模板正常"
  
  # 测试连接池 DBSession
  let session = newPooledDBSession(SQLite, "sqlite://test_session.db")
  echo "✅ 连接池 DBSession 创建成功"
  
  # 查看统计信息
  let (total, available, inUse) = getPoolStats(session)
  echo "连接池状态: 总连接数=", total, ", 可用=", available, ", 使用中=", inUse
  
  # 清理和关闭
  cleanupIdleConnections(session)
  shutdown(session)
  shutdown(pool)
  echo "✅ 连接池测试完成"

when isMainModule:
  testConnectionPool() 