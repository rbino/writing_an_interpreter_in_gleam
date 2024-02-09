import gleeunit
import gleeunit/should
import gleam/list
import monkey/lexer
import monkey/token

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn next_token_test() {
  let input =
    "let five = 5;
let ten = 10;
let add = fn(x, y) {
  x + y;
};
let result = add(five, ten);   
"

  let expected_tokens = [
    token.Token(token_type: token.Let, literal: "let"),
    token.Token(token_type: token.Ident, literal: "five"),
    token.Token(token_type: token.Assign, literal: "="),
    token.Token(token_type: token.Int, literal: "5"),
    token.Token(token_type: token.Semicolon, literal: ";"),
    token.Token(token_type: token.Let, literal: "let"),
    token.Token(token_type: token.Ident, literal: "ten"),
    token.Token(token_type: token.Assign, literal: "="),
    token.Token(token_type: token.Int, literal: "10"),
    token.Token(token_type: token.Semicolon, literal: ";"),
    token.Token(token_type: token.Let, literal: "let"),
    token.Token(token_type: token.Ident, literal: "add"),
    token.Token(token_type: token.Assign, literal: "="),
    token.Token(token_type: token.Function, literal: "fn"),
    token.Token(token_type: token.LParen, literal: "("),
    token.Token(token_type: token.Ident, literal: "x"),
    token.Token(token_type: token.Comma, literal: ","),
    token.Token(token_type: token.Ident, literal: "y"),
    token.Token(token_type: token.RParen, literal: ")"),
    token.Token(token_type: token.LBrace, literal: "{"),
    token.Token(token_type: token.Ident, literal: "x"),
    token.Token(token_type: token.Plus, literal: "+"),
    token.Token(token_type: token.Ident, literal: "y"),
    token.Token(token_type: token.Semicolon, literal: ";"),
    token.Token(token_type: token.RBrace, literal: "}"),
    token.Token(token_type: token.Semicolon, literal: ";"),
    token.Token(token_type: token.Let, literal: "let"),
    token.Token(token_type: token.Ident, literal: "result"),
    token.Token(token_type: token.Assign, literal: "="),
    token.Token(token_type: token.Ident, literal: "add"),
    token.Token(token_type: token.LParen, literal: "("),
    token.Token(token_type: token.Ident, literal: "five"),
    token.Token(token_type: token.Comma, literal: ","),
    token.Token(token_type: token.Ident, literal: "ten"),
    token.Token(token_type: token.RParen, literal: ")"),
    token.Token(token_type: token.Semicolon, literal: ";"),
    token.Token(token_type: token.Eof, literal: ""),
  ]

  let lexer = lexer.new(input)

  let verify = fn(lexer, expected: token.Token) {
    let #(token, lexer) = lexer.next_token(lexer)

    token.token_type
    |> should.equal(expected.token_type)

    token.literal
    |> should.equal(expected.literal)

    lexer
  }

  list.fold(expected_tokens, lexer, verify)
}
