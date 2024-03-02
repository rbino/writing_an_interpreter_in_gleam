import gleam/list
import gleam/result
import monkey/ast
import monkey/builtin
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
    ast.Ident(name) -> eval_identifier(name, env)
    ast.Int(value) -> Ok(#(obj.Int(value), env))
    ast.String(value) -> Ok(#(obj.String(value), env))
    ast.Array(elements) -> {
      use #(values, env) <- result.map(eval_expressions(elements, env))
      #(obj.Array(values), env)
    }
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
    ast.Index(lhs, index) -> {
      use #(lhs_obj, env) <- result.try(do_eval(lhs, env))
      use #(index_obj, env) <- result.try(do_eval(index, env))
      eval_indexing(lhs_obj, index_obj, env)
    }
  }
}

fn eval_identifier(name, env) {
  let result =
    obj.get_env(env, name)
    |> result.lazy_or(fn() { builtin.get(name) })

  case result {
    Ok(value) -> Ok(#(value, env))

    Error(Nil) -> {
      let err = obj.unknown_identifier_error(name)
      Error(#(err, env))
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
      let err = obj.unsupported_unary_op_error(ast.Negate, rhs)
      Error(#(err, env))
    }
  }
}

fn eval_indexing(lhs, index, env) {
  case lhs, index {
    obj.Array(elements), obj.Int(i) -> {
      let value =
        list.at(elements, i)
        |> result.unwrap(obj.Null)
      Ok(#(value, env))
    }

    obj.Array(_), _ -> Error(#(obj.invalid_index_error(index), env))
    _, _ -> Error(#(obj.invalid_indexed_object_error(lhs), env))
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
      let err = obj.unsupported_binary_op_error(op, lhs, rhs)
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
  case fun {
    obj.Fn(params, body, stored_env) ->
      case list.strict_zip(params, args) {
        Error(list.LengthMismatch) -> {
          let expected = list.length(params)
          let actual = list.length(args)
          Error(#(obj.bad_arity_error(expected, actual), outer_env))
        }
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

    obj.Builtin(f) ->
      case f(args) {
        Ok(return_value) -> Ok(#(return_value, outer_env))
        Error(err) -> Error(#(err, outer_env))
      }

    _ -> Error(#(obj.bad_function_error(fun), outer_env))
  }
}

fn bool_obj(bool) {
  case bool {
    True -> obj.True
    False -> obj.False
  }
}
