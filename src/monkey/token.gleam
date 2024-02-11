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
