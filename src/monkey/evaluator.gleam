import gleam/list
import gleam/result
import monkey/ast
import monkey/obj

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
    _ -> Error(Nil)
  }
}

fn eval_bang(rhs) {
  case rhs {
    obj.False | obj.Null -> obj.True
    _ -> obj.False
  }
}
