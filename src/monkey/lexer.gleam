import gleam/bit_array
import gleam/list
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

fn char_token_type(char: String) -> Result(token.TokenType, Nil) {
  case char {
    "=" -> Ok(token.Assign)
    ";" -> Ok(token.Semicolon)
    "(" -> Ok(token.LParen)
    ")" -> Ok(token.RParen)
    "," -> Ok(token.Comma)
    "+" -> Ok(token.Plus)
    "-" -> Ok(token.Minus)
    "*" -> Ok(token.Asterisk)
    "/" -> Ok(token.Slash)
    "!" -> Ok(token.Bang)
    "<" -> Ok(token.LT)
    ">" -> Ok(token.GT)
    "{" -> Ok(token.LBrace)
    "}" -> Ok(token.RBrace)
    _ -> Error(Nil)
  }
}

pub fn next_token(lexer: Lexer) -> #(token.Token, Lexer) {
  let lexer = skip_whitespace(lexer)

  lexer
  |> read_operator()
  |> result.lazy_unwrap(fn() {
    lexer
    |> read_identifier()
    |> result.lazy_unwrap(fn() {
      lexer
      |> read_digit()
      |> result.lazy_unwrap(fn() {
        case lexer.ch {
          Ok(char) -> consume_char_token(lexer, token.Illegal, char)
          Error(Nil) -> #(
            token.Token(token_type: token.Eof, literal: ""),
            lexer,
          )
        }
      })
    })
  })
}

fn skip_whitespace(lexer: Lexer) -> Lexer {
  case lexer.ch {
    Ok(c) ->
      case is_whitespace(c) {
        True ->
          lexer
          |> read_char()
          |> skip_whitespace()

        False -> lexer
      }

    Error(Nil) -> lexer
  }
}

fn read_operator(lexer: Lexer) -> Result(#(token.Token, Lexer), Nil) {
  result.try(lexer.ch, fn(char) {
    result.try(char_token_type(char), fn(token_type) {
      Ok(consume_char_token(lexer, token_type, char))
    })
  })
}

fn consume_char_token(lexer, token_type, ch) -> #(token.Token, Lexer) {
  #(token.Token(token_type, ch), read_char(lexer))
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
  result.try(lexer.ch, fn(char) {
    case is_letter(char) {
      True -> {
        let #(lexer, builder) =
          read_while(lexer, string_builder.new(), is_letter)
        let literal = string_builder.to_string(builder)
        let token_type = lookup_identifier_type(literal)
        Ok(#(token.Token(token_type, literal), lexer))
      }

      False -> Error(Nil)
    }
  })
}

fn read_digit(lexer: Lexer) -> Result(#(token.Token, Lexer), Nil) {
  result.try(lexer.ch, fn(char) {
    case is_digit(char) {
      True -> {
        let #(lexer, builder) =
          read_while(lexer, string_builder.new(), is_digit)
        let literal = string_builder.to_string(builder)
        Ok(#(token.Token(token.Int, literal), lexer))
      }

      False -> Error(Nil)
    }
  })
}

fn read_while(lexer: Lexer, builder, predicate) {
  lexer.ch
  |> result.try(fn(char) {
    case predicate(char) {
      True -> Ok(char)
      False -> Error(Nil)
    }
  })
  |> result.map(fn(char) {
    let builder = string_builder.append(builder, char)
    let lexer = read_char(lexer)
    read_while(lexer, builder, predicate)
  })
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
