import gleam/dict
import gleam/int

pub type Error {
  TypeError(msg: String)
  UnknownIdentifierError(msg: String)
  UnsupportedError
}

pub type Env {
  Env(store: dict.Dict(String, Object))
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
        UnknownIdentifierError(msg) -> "UnknownIdentifierError: " <> msg
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

pub fn new_env() {
  Env(store: dict.new())
}

pub fn get_env(env: Env, name) {
  dict.get(env.store, name)
}

pub fn set_env(env: Env, name, value) {
  Env(store: dict.insert(env.store, name, value))
}
