import gleam/dict
import gleam/int
import gleam/string
import monkey/ast

pub type Error {
  BadArityError(msg: String)
  BadFunctionError(msg: String)
  TypeError(msg: String)
  UnknownIdentifierError(msg: String)
}

pub type Env {
  Env(store: dict.Dict(String, Object))
}

pub type Object {
  Int(Int)
  String(String)
  True
  False
  Null
  Fn(params: List(String), body: ast.Node, env: Env)
  ReturnValue(Object)
  Error(Error)
}

pub fn inspect(obj) {
  case obj {
    Int(value) -> int.to_string(value)
    String(value) -> "\"" <> value <> "\""
    True -> "true"
    False -> "false"
    Null -> "null"
    Fn(params, body, _env) ->
      "fn(" <> string.join(params, ", ") <> ") " <> ast.to_string(body)
    ReturnValue(obj) -> inspect(obj)
    Error(err_type) ->
      case err_type {
        BadArityError(msg) -> "BadArityError: " <> msg
        BadFunctionError(msg) -> "BadFunctionError: " <> msg
        TypeError(msg) -> "TypeError: " <> msg
        UnknownIdentifierError(msg) -> "UnknownIdentifierError: " <> msg
      }
  }
}

pub fn object_type(obj) {
  case obj {
    Int(_) -> "int"
    String(_) -> "string"
    True | False -> "bool"
    Null -> "null"
    Fn(_, _, _) -> "function"
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
