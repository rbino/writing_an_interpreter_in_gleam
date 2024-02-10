pub type TokenType {
  Illegal
  Eof

  // Identifiers + literals
  Ident
  Int

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

pub type Token {
  Token(token_type: TokenType, literal: String)
}
