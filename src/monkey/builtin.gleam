import gleam/list
import gleam/string
import monkey/obj

pub fn get(name) {
  case name {
    "len" -> Ok(obj.Builtin(builtin_len))
    "first" -> Ok(obj.Builtin(builtin_first))
    "last" -> Ok(obj.Builtin(builtin_last))
    "rest" -> Ok(obj.Builtin(builtin_rest))
    _ -> Error(Nil)
  }
}

fn builtin_len(args) {
  case args {
    [obj.String(s)] -> Ok(obj.Int(string.length(s)))
    [obj.Array(elems)] -> Ok(obj.Int(list.length(elems)))
    [other_type] -> {
      let msg =
        "object of type " <> obj.object_type(other_type) <> " has no len()"
      obj.TypeError(msg)
      |> obj.Error()
      |> Error()
    }
    _ -> bad_arity(1, list.length(args))
  }
}

fn first(elems) {
  case elems {
    [elem, ..] -> Ok(elem)
    [] -> Ok(obj.Null)
  }
}

fn builtin_first(args) {
  array_builtin(args, first)
}

fn rest(elems) {
  case elems {
    [_, ..rest] -> Ok(obj.Array(rest))
    [] -> Ok(obj.Null)
  }
}

fn builtin_rest(args) {
  array_builtin(args, rest)
}

fn last(elems) {
  case elems {
    [last] -> Ok(last)
    [_, ..rest] -> last(rest)
    [] -> Ok(obj.Null)
  }
}

fn builtin_last(args) {
  array_builtin(args, last)
}

fn array_builtin(args, fun) {
  case args {
    [obj.Array(elems)] -> fun(elems)

    [other_type] -> {
      let msg = "can't call first() on type " <> obj.object_type(other_type)
      obj.TypeError(msg)
      |> obj.Error()
      |> Error()
    }

    _ -> bad_arity(1, list.length(args))
  }
}

fn bad_arity(expected, actual) {
  Error(obj.bad_arity_error(expected, actual))
}
