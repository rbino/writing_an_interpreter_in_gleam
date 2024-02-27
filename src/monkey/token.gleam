import gleam/int

pub type Token {
  Illegal(value: String)
  Eof

  // Identifiers + literals
  Ident(value: String)
  Int(value: Int)

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

  LParen
  RParen
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
    Eof -> "EOF"
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
    LParen -> "("
    RParen -> ")"
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
