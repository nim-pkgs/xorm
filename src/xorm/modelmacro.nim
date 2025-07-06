import macros
import std/tables
import annotations

# ========== 全局注册表 ==========
var modelRegistry* {.compileTime.}: Table[string, ModelMeta] = initTable[string, ModelMeta]()

# 运行时注册表
var runtimeModelRegistry*: Table[string, ModelMeta] = initTable[string, ModelMeta]()

# ========== 模型注册模板 ==========
template registerModel*(T: typedesc) =
  ## 注册模型类型到 XORM 系统
  ## 
  ## 用法：
  ## ```nim
  ## type User = object
  ##   id {.pk.}: int
  ##   name {.notnull.}: string
  ## 
  ## registerModel(User)
  ## ```
  static:
    let typeInst = getTypeImpl(T)
    if typeInst.kind != nnkObjectTy:
      error("Expected object type, got " & $typeInst.kind)
    let objFields = typeInst[2]
    if objFields.kind != nnkRecList:
      error("Expected record list")
    var fields: seq[FieldAnnotation] = @[]
    for i in 0..<objFields.len:
      let field = objFields[i]
      if field.kind == nnkIdentDefs:
        let fieldName = field[0].strVal
        let fieldType = $field[1]
        var annotation = FieldAnnotation(
          name: fieldName,
          typ: fieldType,
          dbType: inferDbType(fieldType),
          isPrimary: false,
          isAutoIncrement: false,
          isUnique: false,
          isNotNull: false,
          defaultValue: "",
          foreignKey: "",
          foreignTable: "",
          indexName: "",
          isIndexed: false,
          columnName: fieldName,
          isIgnored: false
        )
        if field[0].kind == nnkPragmaExpr:
          let pragmaList = field[0][1]
          for j in 0..<pragmaList.len:
            let pragma = pragmaList[j]
            if pragma.kind == nnkIdent:
              let s = pragma.strVal
              if s == "pk":
                annotation.isPrimary = true
                annotation.isAutoIncrement = true
              elif s == "unique":
                annotation.isUnique = true
              elif s == "notnull":
                annotation.isNotNull = true
              elif s == "ignore":
                annotation.isIgnored = true
            elif pragma.kind == nnkExprColonExpr:
              let key = pragma[0].strVal
              let val = pragma[1]
              if key == "default" and val.kind == nnkStrLit:
                annotation.defaultValue = val.strVal
              elif key == "index":
                annotation.isIndexed = true
                if val.kind == nnkStrLit:
                  annotation.indexName = val.strVal
                else:
                  annotation.indexName = "idx_" & fieldName
              elif key == "column" and val.kind == nnkStrLit:
                annotation.columnName = val.strVal
              elif key == "fk":
                annotation.foreignKey = $val
                annotation.foreignTable = $val
            elif pragma.kind == nnkCall:
              let key = pragma[0].strVal
              if key == "default" and pragma.len > 1 and pragma[1].kind == nnkStrLit:
                annotation.defaultValue = pragma[1].strVal
              elif key == "index":
                annotation.isIndexed = true
                if pragma.len > 1 and pragma[1].kind == nnkStrLit:
                  annotation.indexName = pragma[1].strVal
                else:
                  annotation.indexName = "idx_" & fieldName
              elif key == "column" and pragma.len > 1 and pragma[1].kind == nnkStrLit:
                annotation.columnName = pragma[1].strVal
              elif key == "fk" and pragma.len > 1:
                annotation.foreignKey = $pragma[1]
                annotation.foreignTable = $pragma[1]
        fields.add(annotation)
    let typeName = $T
    modelRegistry[typeName] = ModelMeta(name: typeName, fields: fields)
  
  # 运行时注册
  const typeName = $T
  const meta = modelRegistry[typeName]
  runtimeModelRegistry[typeName] = meta

# ========== 数据库类型推断 ==========
# 使用 core.nim 中的 inferDbType 函数

# ========== 模型元数据访问 ==========
proc getModelMeta*(typeName: string): ModelMeta =
  ## 获取模型元数据
  if not runtimeModelRegistry.hasKey(typeName):
    raise newException(ValueError, "Model not registered: " & typeName)
  runtimeModelRegistry[typeName]

proc getModelMeta*[T](): ModelMeta =
  ## 获取模型元数据（泛型版本）
  getModelMeta($T)

proc isModelRegistered*(typeName: string): bool =
  ## 检查模型是否已注册
  runtimeModelRegistry.hasKey(typeName)

proc isModelRegistered*[T](): bool =
  ## 检查模型是否已注册（泛型版本）
  isModelRegistered($T)

# ========== 导出功能 ==========
export registerModel, getModelMeta, isModelRegistered 