import gleam/int

pub type Program {
  List(Node)
}

pub type Operator {
  Bang
  Plus
  Minus
  Asterisk
  Slash
  GT
  LT
  Eq
  NotEq
}

pub type Node {
  Let(name: String, value: Node)
  Return(value: Node)
  Ident(ident: String)
  Int(value: Int)
  True
  False
  Prefix(op: Operator, rhs: Node)
  Infix(lhs: Node, op: Operator, rhs: Node)
}

pub fn to_string(node) {
  let op_to_string = fn(op) {
    case op {
      Bang -> "!"
      Plus -> "+"
      Minus -> "-"
      Asterisk -> "*"
      Slash -> "/"
      GT -> ">"
      LT -> "<"
      Eq -> "=="
      NotEq -> "!="
    }
  }

  case node {
    Let(name: name, value: value) ->
      "let " <> name <> " = " <> to_string(value) <> ";"
    Return(value) -> "return " <> to_string(value) <> ";"
    Ident(value) -> value
    Int(value) -> int.to_string(value)
    True -> "true"
    False -> "false"
    Prefix(op: op, rhs: rhs) -> "(" <> op_to_string(op) <> to_string(rhs) <> ")"
    Infix(lhs: lhs, op: op, rhs: rhs) ->
      "("
      <> to_string(lhs)
      <> " "
      <> op_to_string(op)
      <> " "
      <> to_string(rhs)
      <> ")"
  }
}
