## XORM - A Simple ORM Framework for Nim
## Inspired by the design from liaoxuefeng.com

# 导入核心模块
import ./core
import ./database
import ./crud
import ./annotations
import ./modelmacro
import ./migration
import ./connectionpool
import ./pooled_session

# 重新导出所有公共 API
export core.DatabaseType, core.FieldInfo, core.TableInfo, core.Mapper, core.QueryBuilder, core.DBSession
export core.newDBSession, core.connect, core.disconnect, core.execute
export core.query, core.where, core.orderBy, core.limit, core.offset, core.buildSql, core.list, core.unique, core.first
export core.inferDbType, core.getOrCreateMapper

# 导出事务支持
export core.beginTransaction, core.commit, core.rollback, core.withTransaction

# 导出 CRUD 操作
export crud.dbInsert, crud.dbUpdate, crud.dbDelete, crud.dbGet
export crud.xinsert, crud.xupdate, crud.xdelete, crud.xget
export crud.save, crud.find, crud.remove

# 导出注解系统
export annotations.FieldAnnotation, annotations.TableAnnotation
export annotations.pk, annotations.fk, annotations.unique, annotations.notnull, annotations.default, annotations.index, annotations.column
export annotations.parseFieldAnnotation, annotations.generateCreateTableSQL

# 导出模型系统
export modelmacro.registerModel, modelmacro.getModelMeta, modelmacro.isModelRegistered

# 导出迁移系统
export migration.createTable, migration.dropTable, migration.createAllTables, migration.dropAllTables

# 导出连接池功能
export connectionpool.PoolConfig, connectionpool.PooledConnection, connectionpool.ConnectionPool
export connectionpool.defaultPoolConfig, connectionpool.newConnectionPool
export connectionpool.getConnection, connectionpool.releaseConnection, connectionpool.withConnection
export connectionpool.getPoolStats, connectionpool.shutdown, connectionpool.cleanupIdleConnections

# 导出连接池 DBSession
export pooled_session.PooledDBSession, pooled_session.newPooledDBSession
export pooled_session.query, pooled_session.xinsert, pooled_session.xupdate, pooled_session.xdelete, pooled_session.xget
export pooled_session.getPoolStats, pooled_session.cleanupIdleConnections, pooled_session.shutdown

# 为了方便使用，提供一个 fromQuery 别名
proc fromQuery*[T](session: DBSession, entityType: typedesc[T]): QueryBuilder[T] =
  query(session, entityType) 