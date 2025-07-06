import ../src/xorm/xorm

type User = object
  id: int
  name: string
  email: string

proc testModelRegistration() =
  echo "=== 模型注册测试 ==="
  
  # 注册模型
  registerModel(User)
  echo "✅ 模型注册成功"
  
  # 检查模型是否注册
  if isModelRegistered("User"):
    echo "✅ 模型注册状态检查通过"
  else:
    echo "❌ 模型注册状态检查失败"
  
  # 获取模型元数据
  let userMeta = getModelMeta("User")
  echo "✅ 获取模型元数据成功"
  echo "模型名称: ", userMeta.name
  echo "字段数量: ", userMeta.fields.len
  
  # 测试模型元数据
  echo "✅ 模型元数据获取成功"
  echo "模型名称: ", userMeta.name
  echo "字段数量: ", userMeta.fields.len
  
  echo "✅ 模型注册测试完成"

when isMainModule:
  testModelRegistration() 