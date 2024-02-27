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
    ast.Bang(rhs) -> {
      use rhs_obj <- result.map(do_eval(rhs))
      eval_bang(rhs_obj)
    }
    ast.Minus(rhs) -> {
      use rhs_obj <- result.try(do_eval(rhs))
      eval_minus(rhs_obj)
    }
    _ -> Error(Unsupported)
  }
}

fn eval_bang(rhs) {
  case rhs {
    obj.False | obj.Null -> obj.True
    _ -> obj.False
  }
}

fn eval_minus(rhs) {
  case rhs {
    obj.Int(value) -> Ok(obj.Int(-value))
    _ -> Error(ArithmeticError)
  }
}
