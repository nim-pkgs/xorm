## XORM - 数据库连接层

import std/[strutils, os, strformat]

# 导入数据库驱动
import db_connector/db_common
import db_connector/db_mysql
import db_connector/db_sqlite
import db_connector/db_postgres

# 数据库连接接口
type
  DBConnection* = ref object of RootObj
    isConnected*: bool
    connectionString*: string
    inTransaction*: bool

  SQLiteConnection* = ref object of DBConnection
    db*: db_sqlite.DbConn

  PostgreSQLConnection* = ref object of DBConnection
    host*: string
    port*: int
    database*: string
    username*: string
    password*: string
    db*: db_postgres.DbConn

  MySQLConnection* = ref object of DBConnection
    host*: string
    port*: int
    database*: string
    username*: string
    password*: string
    db*: db_mysql.DbConn

  ResultSet* = ref object
    columns*: seq[string]
    rows*: seq[seq[string]]
    rowIndex*: int
    affectedRows*: int
    lastInsertId*: int

# 数据库连接工厂
proc newSQLiteConnection*(connectionString: string): SQLiteConnection =
  result = SQLiteConnection(
    connectionString: connectionString,
    isConnected: false,
    inTransaction: false
  )

proc newPostgreSQLConnection*(connectionString: string): PostgreSQLConnection =
  result = PostgreSQLConnection(
    connectionString: connectionString,
    isConnected: false,
    inTransaction: false,
    host: "localhost",
    port: 5432,
    database: "",
    username: "",
    password: ""
  )
  # 解析连接字符串 postgresql://user:pass@host:port/db
  if connectionString.startsWith("postgresql://"):
    let url = connectionString[13..^1]
    let parts = url.split("@")
    if parts.len == 2:
      let auth = parts[0].split(":")
      if auth.len == 2:
        result.username = auth[0]
        result.password = auth[1]
      
      let hostDb = parts[1].split("/")
      if hostDb.len == 2:
        result.database = hostDb[1]
        let hostPort = hostDb[0].split(":")
        if hostPort.len == 2:
          result.host = hostPort[0]
          result.port = parseInt(hostPort[1])
        else:
          result.host = hostPort[0]

proc newMySQLConnection*(connectionString: string): MySQLConnection =
  result = MySQLConnection(
    connectionString: connectionString,
    isConnected: false,
    inTransaction: false,
    host: "localhost",
    port: 3306,
    database: "",
    username: "",
    password: ""
  )
  # 解析连接字符串 mysql://user:pass@host:port/db
  if connectionString.startsWith("mysql://"):
    let url = connectionString[8..^1]
    let parts = url.split("@")
    if parts.len == 2:
      let auth = parts[0].split(":")
      if auth.len == 2:
        result.username = auth[0]
        result.password = auth[1]
      
      let hostDb = parts[1].split("/")
      if hostDb.len == 2:
        result.database = hostDb[1]
        let hostPort = hostDb[0].split(":")
        if hostPort.len == 2:
          result.host = hostPort[0]
          result.port = parseInt(hostPort[1])
        else:
          result.host = hostPort[0]

# 连接方法
proc connect*(connection: SQLiteConnection): bool =
  try:
    # 解析连接字符串
    var dbPath = connection.connectionString
    if dbPath.startsWith("sqlite://"):
      dbPath = dbPath[9..^1]
    
    # 确保目录存在
    let dir = dbPath.splitFile.dir
    if dir.len > 0:
      createDir(dir)
    
    # 连接数据库
    connection.db = db_sqlite.open(dbPath, "", "", "")
    connection.isConnected = true
    result = true
  except Exception as e:
    echo "SQLite 连接错误: ", e.msg
    connection.isConnected = false
    result = false

proc connect*(connection: PostgreSQLConnection): bool =
  try:
    let connStr = fmt"host={connection.host} port={connection.port} dbname={connection.database} user={connection.username} password={connection.password}"
    connection.db = db_postgres.open(connStr, connection.username, connection.password, connection.database)
    connection.isConnected = true
    result = true
  except Exception as e:
    echo "PostgreSQL 连接错误: ", e.msg
    connection.isConnected = false
    result = false

proc connect*(connection: MySQLConnection): bool =
  try:
    let connStr = fmt"{connection.host}:{connection.port}"
    echo "尝试连接 MySQL: ", connStr, " 用户: ", connection.username, " 数据库: ", connection.database
    connection.db = db_mysql.open(connStr, connection.username, connection.password, connection.database)
    connection.isConnected = true
    result = true
  except Exception as e:
    echo "MySQL 连接错误: ", e.msg
    connection.isConnected = false
    result = false

# 断开连接
proc disconnect*(connection: DBConnection) =
  if connection.isConnected:
    # 如果有未提交的事务，回滚
    if connection.inTransaction:
      try:
        if connection of SQLiteConnection:
          SQLiteConnection(connection).db.exec(sql"ROLLBACK")
        elif connection of PostgreSQLConnection:
          PostgreSQLConnection(connection).db.exec(sql"ROLLBACK")
        elif connection of MySQLConnection:
          MySQLConnection(connection).db.exec(sql"ROLLBACK")
      except:
        discard
      connection.inTransaction = false
    
    # 关闭数据库连接
    try:
      if connection of SQLiteConnection:
        SQLiteConnection(connection).db.close()
      elif connection of PostgreSQLConnection:
        PostgreSQLConnection(connection).db.close()
      elif connection of MySQLConnection:
        MySQLConnection(connection).db.close()
    except:
      discard
    
    connection.isConnected = false

# 事务支持
proc beginTransaction*(connection: DBConnection): bool =
  if not connection.isConnected:
    return false
  
  try:
    if connection of SQLiteConnection:
      SQLiteConnection(connection).db.exec(sql"BEGIN TRANSACTION")
    elif connection of PostgreSQLConnection:
      PostgreSQLConnection(connection).db.exec(sql"BEGIN")
    elif connection of MySQLConnection:
      MySQLConnection(connection).db.exec(sql"START TRANSACTION")
    
    connection.inTransaction = true
    result = true
  except Exception as e:
    echo "开始事务失败: ", e.msg
    result = false

proc commit*(connection: DBConnection): bool =
  if not connection.isConnected or not connection.inTransaction:
    return false
  
  try:
    if connection of SQLiteConnection:
      SQLiteConnection(connection).db.exec(sql"COMMIT")
    elif connection of PostgreSQLConnection:
      PostgreSQLConnection(connection).db.exec(sql"COMMIT")
    elif connection of MySQLConnection:
      MySQLConnection(connection).db.exec(sql"COMMIT")
    
    connection.inTransaction = false
    result = true
  except Exception as e:
    echo "提交事务失败: ", e.msg
    result = false

proc rollback*(connection: DBConnection): bool =
  if not connection.isConnected or not connection.inTransaction:
    return false
  
  try:
    if connection of SQLiteConnection:
      SQLiteConnection(connection).db.exec(sql"ROLLBACK")
    elif connection of PostgreSQLConnection:
      PostgreSQLConnection(connection).db.exec(sql"ROLLBACK")
    elif connection of MySQLConnection:
      MySQLConnection(connection).db.exec(sql"ROLLBACK")
    
    connection.inTransaction = false
    result = true
  except Exception as e:
    echo "回滚事务失败: ", e.msg
    result = false

# 执行SQL查询
proc execute*(connection: SQLiteConnection, sql: string, params: seq[string]): ResultSet =
  if not connection.isConnected:
    raise newException(ValueError, "Database not connected")
  
  echo "执行 SQLite 查询: ", sql
  echo "参数: ", params
  
  let sqlQuery = sql(sql)
  let rows = connection.db.getAllRows(sqlQuery, params)
  
  # 获取受影响的行数和最后插入的ID
  var affectedRows = 0
  var lastInsertId = 0
  
  # 简化处理，不依赖特定的数据库API
  if sql.toUpperAscii().startsWith("INSERT") or sql.toUpperAscii().startsWith("UPDATE") or sql.toUpperAscii().startsWith("DELETE"):
    affectedRows = 1  # 默认假设影响1行
  
  result = ResultSet(
    columns: @[],
    rows: rows,
    rowIndex: 0,
    affectedRows: affectedRows,
    lastInsertId: lastInsertId
  )

proc execute*(connection: PostgreSQLConnection, sql: string, params: seq[string]): ResultSet =
  if not connection.isConnected:
    raise newException(ValueError, "Database not connected")
  
  echo "执行 PostgreSQL 查询: ", sql
  echo "参数: ", params
  
  let sqlQuery = sql(sql)
  let rows = connection.db.getAllRows(sqlQuery, params)
  
  # PostgreSQL 的受影响行数处理
  var affectedRows = 0
  var lastInsertId = 0
  
  # 简化处理，不依赖特定的数据库API
  if sql.toUpperAscii().startsWith("INSERT") or sql.toUpperAscii().startsWith("UPDATE") or sql.toUpperAscii().startsWith("DELETE"):
    affectedRows = 1  # 默认假设影响1行
  
  result = ResultSet(
    columns: @[],
    rows: rows,
    rowIndex: 0,
    affectedRows: affectedRows,
    lastInsertId: lastInsertId
  )

proc execute*(connection: MySQLConnection, sql: string, params: seq[string]): ResultSet =
  if not connection.isConnected:
    raise newException(ValueError, "Database not connected")
  
  echo "执行 MySQL 查询: ", sql
  echo "参数: ", params
  
  let sqlQuery = sql(sql)
  let rows = connection.db.getAllRows(sqlQuery, params)
  
  # MySQL 的受影响行数和最后插入ID处理
  var affectedRows = 0
  var lastInsertId = 0
  
  # 简化处理，不依赖特定的数据库API
  if sql.toUpperAscii().startsWith("INSERT") or sql.toUpperAscii().startsWith("UPDATE") or sql.toUpperAscii().startsWith("DELETE"):
    affectedRows = 1  # 默认假设影响1行
  
  result = ResultSet(
    columns: @[],
    rows: rows,
    rowIndex: 0,
    affectedRows: affectedRows,
    lastInsertId: lastInsertId
  )

# 导出类型和函数
export DBConnection, SQLiteConnection, PostgreSQLConnection, MySQLConnection
export ResultSet
export newSQLiteConnection, newPostgreSQLConnection, newMySQLConnection
export connect, disconnect, execute
export beginTransaction, commit, rollback 