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

pub fn bad_arity_error(params, args) {
  let expected_arg_count = list.length(params)
  let actual_arg_count = list.length(args)
  let subj = case expected_arg_count {
    1 -> "argument"
    _ -> "arguments"
  }

  let msg =
    "expected "
    <> int.to_string(expected_arg_count)
    <> " "
    <> subj
    <> ", got "
    <> int.to_string(actual_arg_count)

  BadArityError(msg)
  |> Error()
}
