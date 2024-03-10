import gleam/int

pub type Token {
  Illegal(value: String)

  // Identifiers + literals
  Ident(value: String)
  Int(value: Int)
  String(value: String)

  // Operators
  Assign
  Plus
  Minus
  Bang
  Asterisk
  Slash

  LT
  GT
  Eq
  NotEq

  // Delimiters
  Comma
  Semicolon
  Colon

  LParen
  RParen
  LBracket
  RBracket
  LBrace
  RBrace

  // Keywords
  Fn
  Let
  True
  False
  If
  Else
  Return
}

pub fn to_string(token) {
  case token {
    Ident(value) | Illegal(value) -> value
    Int(value) -> int.to_string(value)
    String(value) -> "\"" <> value <> "\""
    Assign -> "="
    Plus -> "+"
    Minus -> "-"
    Bang -> "!"
    Asterisk -> "*"
    Slash -> "/"
    LT -> "<"
    GT -> ">"
    Eq -> "=="
    NotEq -> "!="
    Comma -> ","
    Semicolon -> ";"
    Colon -> ":"
    LParen -> "("
    RParen -> ")"
    LBracket -> "["
    RBracket -> "]"
    LBrace -> "{"
    RBrace -> "}"
    Fn -> "fn"
    Let -> "let"
    True -> "true"
    False -> "false"
    If -> "if"
    Else -> "else"
    Return -> "return"
  }
}
