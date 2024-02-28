import gleam/list
import gleam/result
import monkey/ast
import monkey/obj

pub type Error {
  ArithmeticError
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
    _ -> Error(ArithmeticError)
  }
}
