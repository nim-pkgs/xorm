version       = "0.1.1"
author        = "Your Name"
description   = "A simple ORM framework for Nim"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.6.0"
requires "db_connector"

task test, "Run tests":
  exec "nim c -r tests/test_orm.nim"

task docs, "Generate documentation":
  exec "nim doc src/xorm.nim" 
