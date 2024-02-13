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
!-/*5;
5 < 10 > 5;

if (5 < 10) {
  return true;
} else {
  return false;
}

10 == 10;
10 != 9;
"

  let expected_tokens = [
    token.Let,
    token.Ident("five"),
    token.Assign,
    token.Int(5),
    token.Semicolon,
    token.Let,
    token.Ident("ten"),
    token.Assign,
    token.Int(10),
    token.Semicolon,
    token.Let,
    token.Ident("add"),
    token.Assign,
    token.Function,
    token.LParen,
    token.Ident("x"),
    token.Comma,
    token.Ident("y"),
    token.RParen,
    token.LBrace,
    token.Ident("x"),
    token.Plus,
    token.Ident("y"),
    token.Semicolon,
    token.RBrace,
    token.Semicolon,
    token.Let,
    token.Ident("result"),
    token.Assign,
    token.Ident("add"),
    token.LParen,
    token.Ident("five"),
    token.Comma,
    token.Ident("ten"),
    token.RParen,
    token.Semicolon,
    token.Bang,
    token.Minus,
    token.Slash,
    token.Asterisk,
    token.Int(5),
    token.Semicolon,
    token.Int(5),
    token.LT,
    token.Int(10),
    token.GT,
    token.Int(5),
    token.Semicolon,
    token.If,
    token.LParen,
    token.Int(5),
    token.LT,
    token.Int(10),
    token.RParen,
    token.LBrace,
    token.Return,
    token.True,
    token.Semicolon,
    token.RBrace,
    token.Else,
    token.LBrace,
    token.Return,
    token.False,
    token.Semicolon,
    token.RBrace,
    token.Int(10),
    token.Eq,
    token.Int(10),
    token.Semicolon,
    token.Int(10),
    token.NotEq,
    token.Int(9),
    token.Semicolon,
    token.Eof,
  ]

  let tokens = lexer.lex(input)

  list.length(tokens)
  |> should.equal(list.length(expected_tokens))

  list.zip(expected_tokens, tokens)
  |> list.each(fn(pair) {
    let #(expected, token) = pair

    token
    |> should.equal(expected)
  })
}
