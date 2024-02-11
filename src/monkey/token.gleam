pub type Token {
  Illegal(value: String)
  Eof

  // Identifiers + literals
  Ident(value: String)
  Int(value: String)

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
  Function
  Let
  True
  False
  If
  Else
  Return
}

pub fn to_string(token) {
  case token {
    Ident(value) | Int(value) | Illegal(value) -> value
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
    Function -> "fun"
    Let -> "let"
    True -> "true"
    False -> "false"
    If -> "if"
    Else -> "else"
    Return -> "return"
  }
}
