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
    ast.Int(value) -> Ok(#(obj.Int(value), env))
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
    ast.Block(statements) -> eval_statements(statements, env)
    ast.Return(value) -> {
      use #(obj, env) <- result.map(do_eval(value, env))
      #(obj.ReturnValue(obj), env)
    }
    _ -> Error(#(obj.Error(obj.UnsupportedError), env))
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
