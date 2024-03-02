import gleam/list
import gleam/string
import monkey/obj

pub fn get(name) {
  case name {
    "len" -> Ok(obj.Builtin(builtin_len))
    _ -> Error(Nil)
  }
}

fn builtin_len(args) {
  case args {
    [obj.String(s)] -> Ok(obj.Int(string.length(s)))
    [other_type] -> {
      let msg =
        "object of type " <> obj.object_type(other_type) <> " has no len()"
      obj.TypeError(msg)
      |> obj.Error()
      |> Error()
    }
    _ -> {
      let expected = 1
      let actual = list.length(args)
      Error(obj.bad_arity_error(expected, actual))
    }
  }
}
