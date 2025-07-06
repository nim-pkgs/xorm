## XORM - 数据库连接池

import std/[tables, times, locks, strformat, strutils]
import ./database
import ./core

# ========== 连接池配置 ==========
type
  PoolConfig* = object
    maxConnections*: int          # 最大连接数
    minConnections*: int          # 最小连接数
    maxIdleTime*: Duration        # 最大空闲时间
    connectionTimeout*: Duration  # 连接超时时间
    healthCheckInterval*: Duration # 健康检查间隔
    testQuery*: string           # 健康检查查询语句

  PooledConnection* = ref object
    connection*: DBConnection     # 实际数据库连接
    lastUsed*: DateTime          # 最后使用时间
    isInUse*: bool               # 是否正在使用
    created*: DateTime           # 创建时间
    useCount*: int               # 使用次数

  ConnectionPool* = ref object
    config*: PoolConfig          # 连接池配置
    connections*: seq[PooledConnection] # 连接列表
    availableConnections*: seq[int] # 可用连接索引
    inUseConnections*: Table[int, DateTime] # 正在使用的连接
    lock*: Lock                  # 线程锁
    dbType*: DatabaseType        # 数据库类型
    connectionString*: string    # 连接字符串
    isShutdown*: bool            # 是否已关闭

# ========== 默认配置 ==========
proc defaultPoolConfig*(): PoolConfig =
  result = PoolConfig(
    maxConnections: 10,
    minConnections: 2,
    maxIdleTime: initDuration(seconds = 300),  # 5分钟
    connectionTimeout: initDuration(seconds = 30),  # 30秒
    healthCheckInterval: initDuration(seconds = 60),  # 1分钟
    testQuery: "SELECT 1"
  )

# ========== 连接池创建和管理 ==========

proc createConnection*(pool: ConnectionPool): bool =
  ## 创建新的数据库连接
  if pool.connections.len >= pool.config.maxConnections:
    return false
  
  var connection: DBConnection
  case pool.dbType
  of SQLite:
    connection = newSQLiteConnection(pool.connectionString)
  of PostgreSQL:
    connection = newPostgreSQLConnection(pool.connectionString)
  of MySQL:
    connection = newMySQLConnection(pool.connectionString)
  
  # 尝试连接
  var success = false
  case pool.dbType
  of SQLite:
    success = SQLiteConnection(connection).connect()
  of PostgreSQL:
    success = PostgreSQLConnection(connection).connect()
  of MySQL:
    success = MySQLConnection(connection).connect()
  
  if success:
    let pooledConn = PooledConnection(
      connection: connection,
      lastUsed: now(),
      isInUse: false,
      created: now(),
      useCount: 0
    )
    
    pool.connections.add(pooledConn)
    pool.availableConnections.add(pool.connections.high)
    return true
  
  return false

proc isConnectionHealthy*(pool: ConnectionPool, pooledConn: PooledConnection): bool =
  ## 检查连接是否健康
  if not pooledConn.connection.isConnected:
    return false
  
  # 检查连接是否超时
  let now = now()
  if now - pooledConn.lastUsed > pool.config.maxIdleTime:
    return false
  
  # 执行健康检查查询
  try:
    case pool.dbType
    of SQLite:
      discard SQLiteConnection(pooledConn.connection).execute(pool.config.testQuery, @[])
    of PostgreSQL:
      discard PostgreSQLConnection(pooledConn.connection).execute(pool.config.testQuery, @[])
    of MySQL:
      discard MySQLConnection(pooledConn.connection).execute(pool.config.testQuery, @[])
    return true
  except:
    return false

proc removeConnection*(pool: ConnectionPool, index: int) =
  ## 移除指定索引的连接
  if index >= 0 and index < pool.connections.len:
    let pooledConn = pool.connections[index]
    
    # 断开连接
    pooledConn.connection.disconnect()
    
    # 从列表中移除
    pool.connections.delete(index)
    
    # 更新可用连接索引
    for i in 0..<pool.availableConnections.len:
      if pool.availableConnections[i] == index:
        pool.availableConnections.delete(i)
        break
      elif pool.availableConnections[i] > index:
        pool.availableConnections[i] -= 1
    
    # 更新正在使用的连接索引
    var newInUse: Table[int, DateTime]
    for idx, time in pairs(pool.inUseConnections):
      if idx == index:
        continue
      elif idx > index:
        newInUse[idx - 1] = time
      else:
        newInUse[idx] = time
    pool.inUseConnections = newInUse

proc newConnectionPool*(dbType: DatabaseType, connectionString: string, config: PoolConfig = defaultPoolConfig()): ConnectionPool =
  ## 创建新的连接池
  result = ConnectionPool(
    config: config,
    connections: @[],
    availableConnections: @[],
    inUseConnections: initTable[int, DateTime](),
    lock: Lock(),
    dbType: dbType,
    connectionString: connectionString,
    isShutdown: false
  )
  
  # 初始化锁
  result.lock.initLock()
  
  # 预创建最小连接数
  for i in 0..<config.minConnections:
    discard result.createConnection()

proc getConnection*(pool: ConnectionPool): DBConnection =
  ## 从连接池获取连接
  pool.lock.acquire()
  defer: pool.lock.release()
  
  if pool.isShutdown:
    raise newException(ValueError, "Connection pool is shutdown")
  
  # 尝试获取可用连接
  while pool.availableConnections.len > 0:
    let index = pool.availableConnections.pop()
    let pooledConn = pool.connections[index]
    
    # 检查连接是否健康
    if pool.isConnectionHealthy(pooledConn):
      pooledConn.isInUse = true
      pooledConn.lastUsed = now()
      pooledConn.useCount += 1
      pool.inUseConnections[index] = now()
      return pooledConn.connection
    else:
      # 移除不健康的连接
      pool.removeConnection(index)
  
  # 如果没有可用连接，尝试创建新连接
  if pool.connections.len < pool.config.maxConnections:
    if pool.createConnection():
      return pool.getConnection()  # 递归调用获取新创建的连接
  
  # 等待可用连接（简化版本，实际应该使用条件变量）
  raise newException(ValueError, "No available connections in pool")

proc releaseConnection*(pool: ConnectionPool, connection: DBConnection) =
  ## 释放连接回连接池
  pool.lock.acquire()
  defer: pool.lock.release()
  
  if pool.isShutdown:
    return
  
  # 查找对应的连接
  for i, pooledConn in pool.connections:
    if pooledConn.connection == connection:
      if pooledConn.isInUse:
        pooledConn.isInUse = false
        pooledConn.lastUsed = now()
        pool.availableConnections.add(i)
        pool.inUseConnections.del(i)
      break

proc cleanupIdleConnections*(pool: ConnectionPool) =
  ## 清理空闲连接
  pool.lock.acquire()
  defer: pool.lock.release()
  
  if pool.isShutdown:
    return
  
  var toRemove: seq[int]
  let now = now()
  
  for i, pooledConn in pool.connections:
    if not pooledConn.isInUse and (now - pooledConn.lastUsed) > pool.config.maxIdleTime:
      toRemove.add(i)
  
  # 从后往前删除，避免索引变化
  for i in countdown(toRemove.high, 0):
    pool.removeConnection(toRemove[i])

proc getPoolStats*(pool: ConnectionPool): (int, int, int) =
  ## 获取连接池统计信息 (总连接数, 可用连接数, 使用中连接数)
  pool.lock.acquire()
  defer: pool.lock.release()
  
  let total = pool.connections.len
  let available = pool.availableConnections.len
  let inUse = pool.inUseConnections.len
  
  return (total, available, inUse)

proc shutdown*(pool: ConnectionPool) =
  ## 关闭连接池
  pool.lock.acquire()
  defer: pool.lock.release()
  
  if pool.isShutdown:
    return
  
  pool.isShutdown = true
  
  # 断开所有连接
  for pooledConn in pool.connections:
    pooledConn.connection.disconnect()
  
  # 清空列表
  pool.connections.setLen(0)
  pool.availableConnections.setLen(0)
  pool.inUseConnections.clear()
  
  # 释放锁
  pool.lock.deinitLock()

# ========== 便利的模板 ==========

template withConnection*(pool: ConnectionPool, connName: untyped, body: untyped): untyped =
  ## 自动管理连接的模板
  let connName = pool.getConnection()
  try:
    body
  finally:
    pool.releaseConnection(connName)

# ========== 导出功能 ==========
export PoolConfig, PooledConnection, ConnectionPool
export defaultPoolConfig, newConnectionPool
export getConnection, releaseConnection, withConnection
export getPoolStats, shutdown, cleanupIdleConnections 