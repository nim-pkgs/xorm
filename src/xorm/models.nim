import ./modelmacro
import ./annotations

# 用户模型定义

type
  User = object
    id {.pk.}: int
    name {.notnull, unique.}: string
    email {.unique, index.}: string
    age {.default: "18".}: int
    created_at {.column: "created_at".}: string
    temp_field {.ignore.}: bool

registerModel(User)

type
  Product = object
    id {.pk.}: int
    name {.notnull.}: string
    price {.default: "0.0".}: float
    category_id {.fk: User.}: int

registerModel(Product) 