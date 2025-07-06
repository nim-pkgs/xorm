import std/strutils
import std/os

proc runAllTests() =
  echo "🚀 开始运行所有测试...\n"
  
  # 使用 Makefile 编译并运行测试
  let nimCmd = "nim c --passL:\"-headerpad_max_install_names\" --passL:\"-Wl,-rpath,/opt/homebrew/opt/mysql-client/lib\" --passL:\"-Wl,-rpath,/opt/homebrew/Cellar/libpq/17.5/lib\" -d:release -r"
  
  # 运行连接池测试
  echo "=== 连接池测试 ==="
  discard execShellCmd(nimCmd & " tests/test_connection_pool.nim")
  echo "\n" & "=".repeat(50) & "\n"
  
  # 运行CRUD测试
  echo "=== CRUD 测试 ==="
  discard execShellCmd(nimCmd & " tests/test_crud.nim")
  echo "\n" & "=".repeat(50) & "\n"
  
  # 运行查询测试
  echo "=== 查询测试 ==="
  discard execShellCmd(nimCmd & " tests/test_query.nim")
  echo "\n" & "=".repeat(50) & "\n"
  
  # 运行注解系统测试
  echo "=== 注解系统测试 ==="
  discard execShellCmd(nimCmd & " tests/test_annotations.nim")
  echo "\n" & "=".repeat(50) & "\n"
  
  # 运行模型注册测试
  echo "=== 模型注册测试 ==="
  discard execShellCmd(nimCmd & " tests/test_model_registration.nim")
  echo "\n" & "=".repeat(50) & "\n"
  
  # 运行MySQL连接测试
  echo "=== MySQL 连接测试 ==="
  discard execShellCmd(nimCmd & " tests/test_mysql.nim")
  echo "\n" & "=".repeat(50) & "\n"
  
  # 运行会话测试
  echo "=== 会话测试 ==="
  discard execShellCmd(nimCmd & " tests/test_session.nim")
  echo "\n" & "=".repeat(50) & "\n"
  
  # 运行迁移测试
  echo "=== 迁移测试 ==="
  discard execShellCmd(nimCmd & " tests/test_migration.nim")
  echo "\n" & "=".repeat(50) & "\n"
  
  echo "🎉 所有测试完成！"

when isMainModule:
  runAllTests() 