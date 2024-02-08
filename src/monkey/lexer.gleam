import gleam/list
import gleam/string
import monkey/token

pub opaque type Lexer {
  Lexer(
    input: List(String),
    position: Int,
    read_position: Int,
    ch: Result(String, Nil),
  )
}

pub fn new(input) -> Lexer {
  let lexer =
    input
    |> string.to_graphemes()
    |> Lexer(0, 0, Error(Nil))

  read_char(lexer)
}

pub fn next_token(lexer: Lexer) -> #(token.Token, Lexer) {
  let token = case lexer.ch {
    Ok("=") -> token.Token(token_type: token.Assign, literal: "=")
    Ok(";") -> token.Token(token_type: token.Semicolon, literal: ";")
    Ok("(") -> token.Token(token_type: token.LParen, literal: "(")
    Ok(")") -> token.Token(token_type: token.RParen, literal: ")")
    Ok(",") -> token.Token(token_type: token.Comma, literal: ",")
    Ok("+") -> token.Token(token_type: token.Plus, literal: "+")
    Ok("{") -> token.Token(token_type: token.LBrace, literal: "{")
    Ok("}") -> token.Token(token_type: token.RBrace, literal: "}")
    Ok(c) -> token.Token(token_type: token.Illegal, literal: c)
    Error(Nil) -> token.Token(token_type: token.Eof, literal: "")
  }
  let lexer = read_char(lexer)

  #(token, lexer)
}

fn read_char(lexer: Lexer) -> Lexer {
  let ch = list.at(lexer.input, lexer.read_position)

  Lexer(
    ..lexer,
    ch: ch,
    position: lexer.read_position,
    read_position: { lexer.read_position + 1 },
  )
}
