import gleam/int

pub type Error {
  TypeError(msg: String)
  UnsupportedError
}

pub type Object {
  Int(Int)
  True
  False
  Null
  ReturnValue(Object)
  Error(Error)
}

pub fn inspect(obj) {
  case obj {
    Int(value) -> int.to_string(value)
    True -> "true"
    False -> "false"
    Null -> "null"
    ReturnValue(obj) -> inspect(obj)
    Error(err_type) ->
      case err_type {
        TypeError(msg) -> "TypeError: " <> msg
        UnsupportedError -> "UnsupportedError"
      }
  }
}

pub fn object_type(obj) {
  case obj {
    Int(_) -> "int"
    True | False -> "bool"
    Null -> "null"
    ReturnValue(_) -> "return_value"
    Error(_) -> "error"
  }
}
