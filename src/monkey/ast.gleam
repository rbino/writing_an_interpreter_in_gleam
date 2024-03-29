import gleam/dict
import gleam/int
import gleam/list
import gleam/string

pub type Program =
  List(Node)

pub type UnaryOperation {
  BooleanNot
  Negate
}

pub type BinaryOperation {
  Add
  Sub
  Mul
  Div
  Eq
  NotEq
  GT
  LT
}

pub type Node {
  Block(List(Node))
  Let(name: String, value: Node)
  Return(value: Node)
  Fn(parameters: List(String), body: Node)
  Call(function: Node, arguments: List(Node))
  If(condition: Node, consequence: Node)
  IfElse(condition: Node, consequence: Node, alternative: Node)
  Ident(ident: String)
  Int(value: Int)
  String(value: String)
  Array(elements: List(Node))
  Hash(elements: dict.Dict(Node, Node))
  Index(lhs: Node, index: Node)
  True
  False
  UnaryOp(op: UnaryOperation, rhs: Node)
  BinaryOp(lhs: Node, op: BinaryOperation, rhs: Node)
}

pub fn unary_op_to_string(op) {
  case op {
    BooleanNot -> "!"
    Negate -> "-"
  }
}

pub fn binary_op_to_string(op) {
  case op {
    Add -> "+"
    Sub -> "-"
    Mul -> "*"
    Div -> "/"
    Eq -> "=="
    NotEq -> "!="
    GT -> ">"
    LT -> "<"
  }
}

pub fn to_string(node) {
  case node {
    Block(statements) -> {
      let statements =
        statements
        |> list.map(to_string)
        |> string.join(with: "; ")

      "{ " <> statements <> " }"
    }
    Let(name: name, value: value) -> "let " <> name <> " = " <> to_string(value)
    Return(value) -> "return " <> to_string(value)
    Fn(parameters, body) ->
      "fn(" <> string.join(parameters, with: ", ") <> ") " <> to_string(body)
    Call(function, arguments) -> {
      let argument_list =
        list.map(arguments, to_string)
        |> string.join(", ")

      to_string(function) <> "(" <> argument_list <> ")"
    }
    If(condition, consequence) ->
      "if (" <> to_string(condition) <> ") " <> to_string(consequence)
    IfElse(condition, consequence, alternative) ->
      "if ("
      <> to_string(condition)
      <> ") "
      <> to_string(consequence)
      <> " else "
      <> to_string(alternative)
    Ident(value) -> value
    Int(value) -> int.to_string(value)
    String(value) -> "\"" <> value <> "\""
    Array(elements) ->
      "["
      <> list.map(elements, to_string)
      |> string.join(", ")
      <> "]"
    Hash(elements) -> {
      let elem_string =
        elements
        |> dict.to_list()
        |> list.map(fn(element) {
          let #(key, value) = element
          to_string(key) <> ": " <> to_string(value)
        })
        |> string.join(", ")

      "{" <> elem_string <> "}"
    }
    Index(lhs, index) ->
      "(" <> to_string(lhs) <> "[" <> to_string(index) <> "])"
    True -> "true"
    False -> "false"
    UnaryOp(op: op, rhs: rhs) ->
      "(" <> unary_op_to_string(op) <> to_string(rhs) <> ")"
    BinaryOp(lhs: lhs, op: op, rhs: rhs) ->
      "("
      <> to_string(lhs)
      <> " "
      <> binary_op_to_string(op)
      <> " "
      <> to_string(rhs)
      <> ")"
  }
}
