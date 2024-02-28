import gleam/int

pub type Object {
  Int(Int)
  True
  False
  Null
  ReturnValue(Object)
}

pub fn inspect(obj) {
  case obj {
    Int(value) -> int.to_string(value)
    True -> "true"
    False -> "false"
    Null -> "null"
    ReturnValue(obj) -> inspect(obj)
  }
}

pub fn object_type(obj) {
  case obj {
    Int(_) -> "int"
    True | False -> "bool"
    Null -> "null"
    ReturnValue(_) -> "return_value"
  }
}
