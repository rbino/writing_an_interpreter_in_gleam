pub type TokenType {
  Illegal
  Eof

  // Identifiers + literals
  Ident
  Int

  // Operators
  Assign
  Plus

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
}

pub type Token {
  Token(token_type: TokenType, literal: String)
}
