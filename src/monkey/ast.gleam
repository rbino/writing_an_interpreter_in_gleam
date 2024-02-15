import gleam/int

pub type Program {
  List(Node)
}

pub type Operator {
  Bang
  Minus
}

pub type Node {
  Let(name: String, value: Node)
  Return(value: Node)
  Ident(ident: String)
  Int(value: Int)
  Prefix(op: Operator, rhs: Node)
}

pub fn to_string(node) {
  let op_to_string = fn(op) {
    case op {
      Bang -> "!"
      Minus -> "-"
    }
  }

  case node {
    Let(name: name, value: value) ->
      "let " <> name <> " = " <> to_string(value) <> ";"
    Return(value) -> "return " <> to_string(value) <> ";"
    Ident(value) -> value
    Int(value) -> int.to_string(value)
    Prefix(op: op, rhs: rhs) -> "(" <> op_to_string(op) <> to_string(rhs) <> ")"
  }
}
