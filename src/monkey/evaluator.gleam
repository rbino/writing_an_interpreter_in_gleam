import gleam/list
import gleam/result
import monkey/ast
import monkey/obj

pub type Error {
  TypeError(msg: String)
  Unsupported
}

pub fn eval(program: ast.Program) {
  list.fold_until(program, Ok(obj.Null), fn(_, statement) {
    case do_eval(statement) {
      Ok(_) as value -> list.Continue(value)
      Error(_) as error -> list.Stop(error)
    }
  })
}

fn do_eval(node) {
  case node {
    ast.Int(value) -> Ok(obj.Int(value))
    ast.True -> Ok(obj.True)
    ast.False -> Ok(obj.False)
    ast.UnaryOp(op: op, rhs: rhs) -> {
      use rhs_obj <- result.try(do_eval(rhs))
      case op {
        ast.BooleanNot -> eval_boolean_not(rhs_obj)
        ast.Negate -> eval_negation(rhs_obj)
      }
    }
    ast.BinaryOp(lhs: lhs, op: op, rhs: rhs) -> {
      use lhs_obj <- result.try(do_eval(lhs))
      use rhs_obj <- result.try(do_eval(rhs))
      eval_infix_expr(op, lhs_obj, rhs_obj)
    }
    _ -> Error(Unsupported)
  }
}

fn eval_boolean_not(rhs) {
  case rhs {
    obj.False | obj.Null -> Ok(obj.True)
    _ -> Ok(obj.False)
  }
}

fn eval_negation(rhs) {
  case rhs {
    obj.Int(value) -> Ok(obj.Int(-value))
    _ ->
      unsupported_unary_op_error(ast.Negate, rhs)
      |> Error()
  }
}

fn eval_infix_expr(op, lhs, rhs) {
  case lhs, rhs {
    obj.Int(lhs), obj.Int(rhs) -> eval_integer_infix_expr(op, lhs, rhs)

    _, _ ->
      unsupported_binary_op_error(op, lhs, rhs)
      |> Error()
  }
}

fn eval_integer_infix_expr(op, lhs, rhs) {
  case op {
    ast.Add -> Ok(obj.Int(lhs + rhs))
    ast.Sub -> Ok(obj.Int(lhs - rhs))
    ast.Mul -> Ok(obj.Int(lhs * rhs))
    ast.Div -> Ok(obj.Int(lhs / rhs))
    ast.LT -> Ok(bool_obj(lhs < rhs))
    ast.GT -> Ok(bool_obj(lhs > rhs))
    ast.Eq -> Ok(bool_obj(lhs == rhs))
    ast.NotEq -> Ok(bool_obj(lhs != rhs))
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
  TypeError(msg)
}

fn unsupported_binary_op_error(op, lhs, rhs) {
  let msg =
    "'"
    <> ast.binary_op_to_string(op)
    <> "' not supported between "
    <> obj.object_type(lhs)
    <> " and "
    <> obj.object_type(rhs)
  TypeError(msg)
}
