import gleam/dict
import gleam/int
import gleam/list
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
  Array(elements: List(Object))
  True
  False
  Null
  Fn(params: List(String), body: ast.Node, env: Env)
  ReturnValue(Object)
  Builtin(fun: fn(List(Object)) -> Result(Object, Object))
  Error(Error)
}

pub fn inspect(obj) {
  case obj {
    Int(value) -> int.to_string(value)
    String(value) -> "\"" <> value <> "\""
    Array(elements) ->
      "["
      <> list.map(elements, inspect)
      |> string.join(", ")
      <> "]"
    True -> "true"
    False -> "false"
    Null -> "null"
    Fn(params, body, _env) ->
      "fn(" <> string.join(params, ", ") <> ") " <> ast.to_string(body)
    ReturnValue(obj) -> inspect(obj)
    Builtin(_) -> "builtin function"
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
    Array(_) -> "array"
    True | False -> "bool"
    Null -> "null"
    Fn(_, _, _) -> "function"
    ReturnValue(_) -> "return_value"
    Builtin(_) -> "builtin"
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

pub fn unsupported_unary_op_error(op, rhs) {
  let msg =
    "'"
    <> ast.unary_op_to_string(op)
    <> "' not supported for type "
    <> object_type(rhs)
  TypeError(msg)
  |> Error()
}

pub fn unsupported_binary_op_error(op, lhs, rhs) {
  let msg =
    "'"
    <> ast.binary_op_to_string(op)
    <> "' not supported between "
    <> object_type(lhs)
    <> " and "
    <> object_type(rhs)
  TypeError(msg)
  |> Error()
}

pub fn unknown_identifier_error(name) {
  let msg = "unknown identifier '" <> name <> "'"
  UnknownIdentifierError(msg)
  |> Error()
}

pub fn bad_function_error(fun) {
  let msg = "expected a function, got: " <> inspect(fun)
  BadFunctionError(msg)
  |> Error()
}

pub fn bad_arity_error(expected, actual) {
  let subj = case expected {
    1 -> "argument"
    _ -> "arguments"
  }

  let msg =
    "expected "
    <> int.to_string(expected)
    <> " "
    <> subj
    <> ", got "
    <> int.to_string(actual)

  BadArityError(msg)
  |> Error()
}

pub fn invalid_index_error(index) {
  let msg = "invalid index type: " <> object_type(index)
  TypeError(msg)
  |> Error()
}

pub fn invalid_indexed_object_error(obj) {
  let msg = "invalid indexed object type: " <> object_type(obj)
  TypeError(msg)
  |> Error()
}
