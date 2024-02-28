import gleam/int

pub type Object {
  Int(Int)
  True
  False
  Null
}

pub fn inspect(obj) {
  case obj {
    Int(value) -> int.to_string(value)
    True -> "true"
    False -> "false"
    Null -> "null"
  }
}

pub fn object_type(obj) {
  case obj {
    Int(_) -> "int"
    True | False -> "bool"
    Null -> "null"
  }
}
