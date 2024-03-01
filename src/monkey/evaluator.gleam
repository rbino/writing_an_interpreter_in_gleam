import gleam/int
import gleam/list
import gleam/result
import monkey/ast
import monkey/obj

pub fn eval(program: ast.Program, env) {
  list.fold_until(program, Ok(#(obj.Null, env)), fn(acc, statement) {
    let assert Ok(#(_, env)) = acc
    case do_eval(statement, env) {
      Ok(#(obj.ReturnValue(obj), env)) -> list.Stop(Ok(#(obj, env)))
      Ok(_) as value_with_env -> list.Continue(value_with_env)
      Error(_) as error_with_env -> list.Stop(error_with_env)
    }
  })
}

fn eval_statements(statements, env) {
  list.fold_until(statements, Ok(#(obj.Null, env)), fn(acc, statement) {
    let assert Ok(#(_, env)) = acc
    case do_eval(statement, env) {
      Ok(#(obj.ReturnValue(_), _)) as return -> list.Stop(return)
      Ok(_) as value_with_env -> list.Continue(value_with_env)
      Error(_) as error_with_env -> list.Stop(error_with_env)
    }
  })
}

fn do_eval(node, env) {
  case node {
    ast.Ident(name) ->
      case obj.get_env(env, name) {
        Ok(value) -> Ok(#(value, env))
        Error(Nil) -> {
          let err = unknown_identifier_error(name)
          Error(#(err, env))
        }
      }
    ast.Int(value) -> Ok(#(obj.Int(value), env))
    ast.String(value) -> Ok(#(obj.String(value), env))
    ast.True -> Ok(#(obj.True, env))
    ast.False -> Ok(#(obj.False, env))
    ast.UnaryOp(op: op, rhs: rhs) -> {
      use #(rhs_obj, env) <- result.try(do_eval(rhs, env))
      case op {
        ast.BooleanNot -> eval_boolean_not(rhs_obj, env)
        ast.Negate -> eval_negation(rhs_obj, env)
      }
    }
    ast.BinaryOp(lhs: lhs, op: op, rhs: rhs) -> {
      use #(lhs_obj, env) <- result.try(do_eval(lhs, env))
      use #(rhs_obj, env) <- result.try(do_eval(rhs, env))
      eval_infix_expr(op, lhs_obj, rhs_obj, env)
    }
    ast.If(condition, consequence) -> {
      use #(condition_obj, env) <- result.try(do_eval(condition, env))
      case condition_obj {
        obj.False | obj.Null -> Ok(#(obj.Null, env))
        _ -> do_eval(consequence, env)
      }
    }
    ast.IfElse(condition, consequence, alternative) -> {
      use #(condition_obj, env) <- result.try(do_eval(condition, env))
      case condition_obj {
        obj.False | obj.Null -> do_eval(alternative, env)
        _ -> do_eval(consequence, env)
      }
    }
    ast.Block(statements) ->
      case eval_statements(statements, env) {
        Ok(#(obj, _block_env)) -> Ok(#(obj, env))
        Error(#(err, _block_env)) -> Error(#(err, env))
      }
    ast.Return(value) -> {
      use #(obj, env) <- result.map(do_eval(value, env))
      #(obj.ReturnValue(obj), env)
    }
    ast.Let(name, value) -> {
      use #(obj, env) <- result.map(do_eval(value, env))
      let env = obj.set_env(env, name, obj)
      #(obj, env)
    }
    ast.Fn(params, body) -> Ok(#(obj.Fn(params, body, env), env))
    ast.Call(fun, args) -> {
      use #(fun_obj, env) <- result.try(do_eval(fun, env))
      use #(arg_values, env) <- result.try(eval_expressions(args, env))
      eval_function_call(fun_obj, arg_values, env)
    }
  }
}

fn eval_boolean_not(rhs, env) {
  case rhs {
    obj.False | obj.Null -> Ok(#(obj.True, env))
    _ -> Ok(#(obj.False, env))
  }
}

fn eval_negation(rhs, env) {
  case rhs {
    obj.Int(value) -> Ok(#(obj.Int(-value), env))
    _ -> {
      let err = unsupported_unary_op_error(ast.Negate, rhs)
      Error(#(err, env))
    }
  }
}

fn eval_infix_expr(op, lhs, rhs, env) {
  case op, lhs, rhs {
    _, obj.Int(lhs), obj.Int(rhs) -> {
      let obj = eval_integer_infix_expr(op, lhs, rhs)
      Ok(#(obj, env))
    }

    ast.Add, obj.String(lhs), obj.String(rhs) ->
      Ok(#(obj.String(lhs <> rhs), env))

    ast.Eq, lhs, rhs -> Ok(#(bool_obj(lhs == rhs), env))
    ast.NotEq, lhs, rhs -> Ok(#(bool_obj(lhs != rhs), env))

    _, _, _ -> {
      let err = unsupported_binary_op_error(op, lhs, rhs)
      Error(#(err, env))
    }
  }
}

fn eval_integer_infix_expr(op, lhs, rhs) {
  case op {
    ast.Add -> obj.Int(lhs + rhs)
    ast.Sub -> obj.Int(lhs - rhs)
    ast.Mul -> obj.Int(lhs * rhs)
    ast.Div -> obj.Int(lhs / rhs)
    ast.LT -> bool_obj(lhs < rhs)
    ast.GT -> bool_obj(lhs > rhs)
    ast.Eq -> bool_obj(lhs == rhs)
    ast.NotEq -> bool_obj(lhs != rhs)
  }
}

fn eval_expressions(exprs, env) {
  let res =
    list.fold_until(exprs, Ok(#([], env)), fn(acc, expr) {
      let assert Ok(#(values, env)) = acc
      case do_eval(expr, env) {
        Ok(#(value, env)) -> list.Continue(Ok(#([value, ..values], env)))
        Error(#(err, env)) -> list.Stop(Error(#(err, env)))
      }
    })

  use #(values, env) <- result.map(res)
  #(list.reverse(values), env)
}

fn eval_function_call(fun, args, outer_env) {
  use #(params, body, stored_env) <- result.try(extract_fn(fun, outer_env))
  case list.strict_zip(params, args) {
    Error(list.LengthMismatch) ->
      Error(#(bad_arity_error(params, args), outer_env))
    Ok(params_with_args) -> {
      let fun_env =
        list.fold(params_with_args, stored_env, fn(env, param_and_arg) {
          let #(param, arg) = param_and_arg
          obj.set_env(env, param, arg)
        })

      use #(return_value, _env) <- result.map(do_eval(body, fun_env))
      #(return_value, outer_env)
    }
  }
}

fn extract_fn(fun, env) {
  case fun {
    obj.Fn(params, body, env) -> Ok(#(params, body, env))
    _ -> Error(#(bad_function_error(fun), env))
  }
}

fn bool_obj(bool) {
  case bool {
    True -> obj.True
    False -> obj.False
  }
}

fn unsupported_unary_op_error(op, rhs) {
  let msg =
    "'"
    <> ast.unary_op_to_string(op)
    <> "' not supported for type "
    <> obj.object_type(rhs)
  obj.TypeError(msg)
  |> obj.Error()
}

fn unsupported_binary_op_error(op, lhs, rhs) {
  let msg =
    "'"
    <> ast.binary_op_to_string(op)
    <> "' not supported between "
    <> obj.object_type(lhs)
    <> " and "
    <> obj.object_type(rhs)
  obj.TypeError(msg)
  |> obj.Error()
}

fn unknown_identifier_error(name) {
  let msg = "unknown identifier '" <> name <> "'"
  obj.UnknownIdentifierError(msg)
  |> obj.Error()
}

fn bad_function_error(fun) {
  let msg = "expected a function, got: " <> obj.inspect(fun)
  obj.BadFunctionError(msg)
  |> obj.Error()
}

fn bad_arity_error(params, args) {
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

  obj.BadArityError(msg)
  |> obj.Error()
}
