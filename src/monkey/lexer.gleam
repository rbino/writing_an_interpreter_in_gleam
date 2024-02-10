import gleam/bit_array
import gleam/bool
import gleam/iterator
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/string_builder
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

pub fn to_iterator(lexer) {
  use acc <- iterator.unfold(from: option.Some(lexer))
  {
    use lexer <- option.map(acc)
    let #(token, lexer) = next_token(lexer)
    case token, lexer {
      token.Token(token_type: token.Eof, literal: _), _ ->
        iterator.Next(element: token, accumulator: option.None)

      _, _ -> iterator.Next(element: token, accumulator: option.Some(lexer))
    }
  }
  |> option.unwrap(iterator.Done)
}

fn symbol_token(char, peeked) {
  let build_token = fn(token_type, literal) {
    Ok(token.Token(token_type, literal))
  }

  case char, peeked {
    "=", option.Some("=") -> build_token(token.Eq, "==")
    "!", option.Some("=") -> build_token(token.NotEq, "!=")
    "=", _ -> build_token(token.Assign, char)
    "!", _ -> build_token(token.Bang, char)
    ";", _ -> build_token(token.Semicolon, char)
    "(", _ -> build_token(token.LParen, char)
    ")", _ -> build_token(token.RParen, char)
    ",", _ -> build_token(token.Comma, char)
    "+", _ -> build_token(token.Plus, char)
    "-", _ -> build_token(token.Minus, char)
    "*", _ -> build_token(token.Asterisk, char)
    "/", _ -> build_token(token.Slash, char)
    "<", _ -> build_token(token.LT, char)
    ">", _ -> build_token(token.GT, char)
    "{", _ -> build_token(token.LBrace, char)
    "}", _ -> build_token(token.RBrace, char)
    _, _ -> Error(Nil)
  }
}

pub fn next_token(lexer: Lexer) -> #(token.Token, Lexer) {
  let lexer = skip_whitespace(lexer)

  use <- result.lazy_unwrap(read_symbol(lexer))
  use <- result.lazy_unwrap(read_identifier(lexer))
  use <- result.lazy_unwrap(read_digit(lexer))

  case lexer.ch {
    Ok(char) -> {
      let token = token.Token(token.Illegal, char)
      #(token, consume_token(lexer, token))
    }
    Error(Nil) -> #(token.Token(token_type: token.Eof, literal: ""), lexer)
  }
}

fn skip_whitespace(lexer: Lexer) -> Lexer {
  {
    use char <- result.try(lexer.ch)
    use <- bool.guard(when: !is_whitespace(char), return: Error(Nil))

    lexer
    |> read_char()
    |> skip_whitespace()
    |> Ok()
  }
  |> result.unwrap(lexer)
}

fn read_symbol(lexer: Lexer) -> Result(#(token.Token, Lexer), Nil) {
  use char <- result.try(lexer.ch)
  use token <- result.try(symbol_token(char, peek_char(lexer)))

  Ok(#(token, consume_token(lexer, token)))
}

fn consume_token(lexer, token: token.Token) -> Lexer {
  token.literal
  |> string.length()
  |> list.range(from: 1, to: _)
  |> list.fold(lexer, fn(lexer, _) { read_char(lexer) })
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

fn peek_char(lexer: Lexer) {
  list.at(lexer.input, lexer.read_position)
  |> option.from_result()
}

fn lookup_identifier_type(identifier) -> token.TokenType {
  case identifier {
    "fn" -> token.Function
    "let" -> token.Let
    "true" -> token.True
    "false" -> token.False
    "if" -> token.If
    "else" -> token.Else
    "return" -> token.Return
    _ -> token.Ident
  }
}

fn read_identifier(lexer: Lexer) -> Result(#(token.Token, Lexer), Nil) {
  use char <- result.try(lexer.ch)
  use <- bool.guard(when: !is_letter(char), return: Error(Nil))

  let #(lexer, builder) = read_while(lexer, string_builder.new(), is_letter)
  let literal = string_builder.to_string(builder)
  let token_type = lookup_identifier_type(literal)
  Ok(#(token.Token(token_type, literal), lexer))
}

fn read_digit(lexer: Lexer) -> Result(#(token.Token, Lexer), Nil) {
  use char <- result.try(lexer.ch)
  use <- bool.guard(when: !is_digit(char), return: Error(Nil))

  let #(lexer, builder) = read_while(lexer, string_builder.new(), is_digit)
  let literal = string_builder.to_string(builder)
  Ok(#(token.Token(token.Int, literal), lexer))
}

fn read_while(lexer: Lexer, builder, predicate) {
  {
    use char <- result.try(lexer.ch)
    use <- bool.guard(when: !predicate(char), return: Error(Nil))

    let builder = string_builder.append(builder, char)
    let lexer = read_char(lexer)
    Ok(read_while(lexer, builder, predicate))
  }
  |> result.unwrap(#(lexer, builder))
}

const lower_a = 97

const lower_z = 122

const upper_a = 65

const upper_z = 90

const underscore = 95

fn is_letter(char) {
  case bit_array.from_string(char) {
    <<c>> if lower_a <= c && c <= lower_z || upper_a <= c && c <= upper_z || c == underscore ->
      True
    _ -> False
  }
}

const zero = 48

const nine = 57

fn is_digit(char) {
  case bit_array.from_string(char) {
    <<c>> if zero <= c && c <= nine -> True
    _ -> False
  }
}

fn is_whitespace(char) {
  case char {
    " " | "\t" | "\n" | "\r" -> True
    _ -> False
  }
}
