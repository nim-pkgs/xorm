## XORM - 支持连接池的 DBSession

import std/[tables, strformat]
from typeinfo import Any, toAny, kind, getString, getBiggestInt, getBiggestFloat, getBool, fields, AnyKind
import ./core
import ./connectionpool
import ./crud

# ========== 连接池 DBSession ==========
type
  PooledDBSession* = ref object
    connectionString*: string
    dbType*: DatabaseType
    connectionPool*: ConnectionPool
    mappers*: Table[string, MapperBase]

# ========== 创建连接池 DBSession ==========
proc newPooledDBSession*(dbType: DatabaseType, connectionString: string, poolConfig: PoolConfig = defaultPoolConfig()): PooledDBSession =
  let pool = newConnectionPool(dbType, connectionString, poolConfig)
  
  result = PooledDBSession(
    dbType: dbType,
    connectionString: connectionString,
    connectionPool: pool,
    mappers: initTable[string, MapperBase]()
  )

# ========== 连接池 DBSession 的查询方法 ==========
proc query*[T](session: PooledDBSession, entityType: typedesc[T]): QueryBuilder[T] =
  # 创建一个临时的DBSession来获取映射器
  let tempSession = DBSession(
    dbType: session.dbType,
    connectionString: session.connectionString,
    connection: nil,
    mappers: session.mappers
  )
  let mapper = getOrCreateMapper[T](tempSession)
  QueryBuilder[T](
    session: session,
    mapper: mapper,
    selectFields: @["*"],
    whereParams: @[]
  )

# ========== 连接池 DBSession 的 CRUD 操作 ==========
proc xinsert*[T](session: PooledDBSession, entity: T): int =
  session.connectionPool.withConnection(conn):
    # 这里需要创建一个临时的DBSession来使用现有的CRUD函数
    let tempSession = DBSession(
      dbType: session.dbType,
      connectionString: session.connectionString,
      connection: conn,
      mappers: session.mappers
    )
    return dbInsert(tempSession, entity)

proc xupdate*[T](session: PooledDBSession, entity: T): bool =
  session.connectionPool.withConnection(conn):
    let tempSession = DBSession(
      dbType: session.dbType,
      connectionString: session.connectionString,
      connection: conn,
      mappers: session.mappers
    )
    return dbUpdate(tempSession, entity)

proc xdelete*[T](session: PooledDBSession, id: int): bool =
  session.connectionPool.withConnection(conn):
    let tempSession = DBSession(
      dbType: session.dbType,
      connectionString: session.connectionString,
      connection: conn,
      mappers: session.mappers
    )
    return dbDelete[T](tempSession, id)

proc xget*[T](session: PooledDBSession, id: int): T =
  session.connectionPool.withConnection(conn):
    let tempSession = DBSession(
      dbType: session.dbType,
      connectionString: session.connectionString,
      connection: conn,
      mappers: session.mappers
    )
    return dbGet[T](tempSession, id)

# ========== 连接池管理 ==========
proc getPoolStats*(session: PooledDBSession): (int, int, int) =
  session.connectionPool.getPoolStats()

proc cleanupIdleConnections*(session: PooledDBSession) =
  session.connectionPool.cleanupIdleConnections()

proc shutdown*(session: PooledDBSession) =
  session.connectionPool.shutdown()

# ========== 导出功能 ==========
export PooledDBSession
export newPooledDBSession
export query, xinsert, xupdate, xdelete, xget
export getPoolStats, cleanupIdleConnections, shutdown 