import gleam/int
import gleam/list
import gleam/string

pub type Program =
  List(Node)

pub type Node {
  Block(List(Node))
  Let(name: String, value: Node)
  Return(value: Node)
  If(condition: Node, consequence: Node)
  IfElse(condition: Node, consequence: Node, alternative: Node)
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
    Block(statements) ->
      statements
      |> list.map(to_string)
      |> string.join(with: "")
    Let(name: name, value: value) ->
      "let " <> name <> " = " <> to_string(value) <> ";"
    Return(value) -> "return " <> to_string(value) <> ";"
    If(condition, consequence) ->
      "if " <> to_string(condition) <> " " <> to_string(consequence)
    IfElse(condition, consequence, alternative) ->
      "if ("
      <> to_string(condition)
      <> ") "
      <> to_string(consequence)
      <> " else "
      <> to_string(alternative)
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
