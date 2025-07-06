 # XORM - A Simple ORM Framework for Nim

A simple Nim ORM framework inspired by [liaoxuefeng.com](https://www.liaoxuefeng.com).

## Features

- 🚀 **Minimal API**: Users only need to define types, `session.query(User)` handles everything automatically
- 🔄 **Auto Reflection**: Runtime automatic analysis of object fields, generating database mappings
- 💾 **Smart Caching**: Automatic mapper caching, avoiding repeated generation
- 🛡️ **Type Safety**: Complete type checking and IDE support
- 🎯 **Go Style**: Clean API design, similar to Go's GORM

## Quick Start

### 1. Define Entity Types

```nim
type
  User = object
    id: int
    name: string
    email: string
    age: int
```

### 2. Create Session and Query

```nim
import xorm

let session = newDBSession(SQLite, "sqlite://test.db")

# Automatically generate mapper and execute query
let users = session.query(User)
  .where("age > ?", 18)
  .orderBy("name")
  .limit(10)
  .list()

echo "Found users: ", users.len
```

## Implemented Features ✅

### Core Architecture
- [x] **Type Definition System** - DatabaseType, FieldInfo, TableInfo, MapperBase, QueryBuilder, DBSession
- [x] **Auto Mapping System** - Runtime reflection, intelligent type inference, mapper caching
- [x] **Database Connections** - SQLite, PostgreSQL, MySQL with transaction support
- [x] **Query Builder** - Basic queries, conditions, result processing, field selection
- [x] **CRUD Operations** - Insert, update, delete, get with convenient aliases
- [x] **Transaction Support** - Begin, commit, rollback, transaction blocks
- [x] **Field Annotations** - Primary key, unique, not null, default, index, column mapping, ignore, foreign key
- [x] **Model Registration** - Compile-time metadata, runtime access, registration status
- [x] **Database Migration** - Create/drop tables, generate SQL, bulk operations
- [x] **Connection Pool** - Pool management, health checking, statistics, cleanup
- [x] **Basic Aggregation** - Count queries via list().len, conditional aggregation
- [x] **Memory Management** - ARC/ORC compatible, stable object lifecycle
- [x] **Complete Test Suite** - Query, CRUD, migration, model registration, annotations, connection pool tests

## Missing Features 🔴

### High Priority
- **Advanced Aggregation** - Native count, sum, avg, max, min functions
- **Association Queries** - Join, leftJoin, rightJoin operations
- **Batch Operations** - Batch insert, update, delete for performance

### Medium Priority
- **Query Optimization** - Preload, groupBy, subquery support
- **Logging System** - Debug, info, warning, error levels
- **Query Caching** - Result caching with TTL

### Low Priority
- **Database Dialects** - SQLite, PostgreSQL, MySQL specific optimizations
- **Version Management** - Migration system with rollback
- **Performance Monitoring** - Slow query detection, statistics

## Project Structure

```
xorm/
├── src/xorm/           # Core source files
├── examples/           # Usage examples
├── tests/             # Test suite
└── README.md          # Documentation
```

## Usage Examples

### Basic Queries
```nim
import xorm

type User = object
  id: int
  name: string
  email: string

let session = newDBSession(SQLite, "sqlite://test.db")

# Query all users
let allUsers = session.query(User).list()

# Conditional query
let activeUsers = session.query(User)
  .where("age > ?", 18)
  .orderBy("name")
  .limit(10)
  .list()

# Get single user
let user = session.query(User)
  .where("id = ?", 1)
  .unique()
```

### CRUD Operations
```nim
# Insert user
let newUser = User(name: "John", email: "john@example.com")
let userId = session.xinsert(newUser)

# Update user
newUser.name = "Jane"
let updated = session.xupdate(newUser)

# Get user
let user = session.xget(User, userId)

# Delete user
let deleted = session.xdelete(User, userId)
```

### Models with Annotations
```nim
type User = object
  id {.pk.}: int
  name {.notnull, unique.}: string
  email {.unique, index.}: string
  age {.default: "18".}: int
  created_at {.column: "created_at".}: string
  temp_field {.ignore.}: bool

registerModel(User)
session.createTable(User)
```

### Transaction Operations
```nim
let success = session.withTransaction:
  let user1 = User(name: "User1", email: "user1@example.com")
  let user2 = User(name: "User2", email: "user2@example.com")
  
  session.xinsert(user1)
  session.xinsert(user2)
```

### Connection Pool Usage
```nim
let pooledSession = newPooledDBSession(SQLite, "sqlite://test.db")
let users = pooledSession.query(User).list()

let (total, available, inUse) = pooledSession.getPoolStats()
echo "Pool status: Total=", total, " Available=", available, " InUse=", inUse

pooledSession.cleanupIdleConnections()
pooledSession.shutdown()
```

### Aggregation Queries
```nim
# Count queries (implemented via list().len)
let userCount = session.query(User).list().len
echo "Total users: ", userCount

let activeUserCount = session.query(User)
  .where("isActive = ?", "1")
  .list().len
echo "Active users: ", activeUserCount
```

## Development Roadmap

### Phase 1: Basic Features ✅ (Completed)
- [x] Database connections (SQLite, PostgreSQL, MySQL)
- [x] CRUD operations and transactions
- [x] Field annotation system and model registration
- [x] Database migration and connection pool
- [x] Complete test suite

### Phase 2: Advanced Query Features (In Progress)
- [ ] Native aggregation queries
- [ ] Association queries (joins)
- [ ] Group queries and subqueries
- [ ] Query optimization features

### Phase 3: Performance Optimization (Planned)
- [ ] Query caching system
- [ ] Batch operation support
- [ ] Performance monitoring
- [ ] Database dialect optimization

### Phase 4: Production Ready (Planned)
- [ ] Complete logging system
- [ ] Database version management
- [ ] Distributed support
- [ ] Performance benchmarking

## Installation

### Prerequisites
- Nim compiler (version 1.6.0 or later)
- SQLite, PostgreSQL, or MySQL database

### Using Nimble
```bash
nimble install xorm
```

### Manual Installation
```bash
git clone https://github.com/your-repo/xorm.git
cd xorm
nimble install
```

## Dependencies

- `db_sqlite` - SQLite database driver
- `db_postgres` - PostgreSQL database driver  
- `db_mysql` - MySQL database driver

## Contributing

We welcome contributions! Please feel free to submit issues and pull requests.

### Development Setup
```bash
git clone https://github.com/your-repo/xorm.git
cd xorm
nimble develop
```

### Running Tests
```bash
nimble test
```

## License

MIT License