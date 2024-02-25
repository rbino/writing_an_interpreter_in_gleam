import gleam/int

pub type Program {
  List(Node)
}

pub type Node {
  Let(name: String, value: Node)
  Return(value: Node)
  Ident(ident: String)
  Int(value: Int)
  True
  False
  Bang(rhs: Node)
  Minus(rhs: Node)
  Add(lhs: Node, rhs: Node)
  Subtract(lhs: Node, rhs: Node)
  Multiply(lhs: Node, rhs: Node)
  Divide(lhs: Node, rhs: Node)
  Eq(lhs: Node, rhs: Node)
  NotEq(lhs: Node, rhs: Node)
  GT(lhs: Node, rhs: Node)
  LT(lhs: Node, rhs: Node)
}

pub fn to_string(node) {
  case node {
    Let(name: name, value: value) ->
      "let " <> name <> " = " <> to_string(value) <> ";"
    Return(value) -> "return " <> to_string(value) <> ";"
    Ident(value) -> value
    Int(value) -> int.to_string(value)
    True -> "true"
    False -> "false"
    Bang(rhs: rhs) -> "(!" <> to_string(rhs) <> ")"
    Minus(rhs: rhs) -> "(-" <> to_string(rhs) <> ")"
    Add(lhs: lhs, rhs: rhs) ->
      "(" <> to_string(lhs) <> " + " <> to_string(rhs) <> ")"
    Subtract(lhs: lhs, rhs: rhs) ->
      "(" <> to_string(lhs) <> " - " <> to_string(rhs) <> ")"
    Multiply(lhs: lhs, rhs: rhs) ->
      "(" <> to_string(lhs) <> " * " <> to_string(rhs) <> ")"
    Divide(lhs: lhs, rhs: rhs) ->
      "(" <> to_string(lhs) <> " / " <> to_string(rhs) <> ")"
    Eq(lhs: lhs, rhs: rhs) ->
      "(" <> to_string(lhs) <> " == " <> to_string(rhs) <> ")"
    NotEq(lhs: lhs, rhs: rhs) ->
      "(" <> to_string(lhs) <> " != " <> to_string(rhs) <> ")"
    GT(lhs: lhs, rhs: rhs) ->
      "(" <> to_string(lhs) <> " > " <> to_string(rhs) <> ")"
    LT(lhs: lhs, rhs: rhs) ->
      "(" <> to_string(lhs) <> " < " <> to_string(rhs) <> ")"
  }
}
