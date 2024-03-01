import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/int
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

pub fn lex(input) -> List(token.Token) {
  let graphemes = string.to_graphemes(input)
  do_lex([], graphemes)
}

fn do_lex(tokens, remaining) {
  let lex_digit = fn(remaining) {
    let digit_length = digit_length(remaining)
    let #(digit_chars, rest) = list.split(remaining, digit_length)
    // We lexed only digit chars, so it's legit to assert here
    let assert Ok(value) =
      string.join(digit_chars, with: "")
      |> int.parse()
    do_lex([token.Int(value), ..tokens], rest)
  }

  let lex_ident = fn(remaining) {
    let ident_length = ident_length(remaining)
    let #(ident_chars, rest) = list.split(remaining, ident_length)
    let value = string.join(ident_chars, with: "")
    do_lex([token.Ident(value), ..tokens], rest)
  }

  case remaining {
    ["r", "e", "t", "u", "r", "n", ..rest] ->
      do_lex([token.Return, ..tokens], rest)
    ["f", "a", "l", "s", "e", ..rest] -> do_lex([token.False, ..tokens], rest)
    ["t", "r", "u", "e", ..rest] -> do_lex([token.True, ..tokens], rest)
    ["e", "l", "s", "e", ..rest] -> do_lex([token.Else, ..tokens], rest)
    ["l", "e", "t", ..rest] -> do_lex([token.Let, ..tokens], rest)
    ["f", "n", ..rest] -> do_lex([token.Fn, ..tokens], rest)
    ["i", "f", ..rest] -> do_lex([token.If, ..tokens], rest)
    ["=", "=", ..rest] -> do_lex([token.Eq, ..tokens], rest)
    ["!", "=", ..rest] -> do_lex([token.NotEq, ..tokens], rest)
    ["(", ..rest] -> do_lex([token.LParen, ..tokens], rest)
    [")", ..rest] -> do_lex([token.RParen, ..tokens], rest)
    ["{", ..rest] -> do_lex([token.LBrace, ..tokens], rest)
    ["}", ..rest] -> do_lex([token.RBrace, ..tokens], rest)
    ["=", ..rest] -> do_lex([token.Assign, ..tokens], rest)
    ["!", ..rest] -> do_lex([token.Bang, ..tokens], rest)
    [";", ..rest] -> do_lex([token.Semicolon, ..tokens], rest)
    [",", ..rest] -> do_lex([token.Comma, ..tokens], rest)
    ["+", ..rest] -> do_lex([token.Plus, ..tokens], rest)
    ["-", ..rest] -> do_lex([token.Minus, ..tokens], rest)
    ["*", ..rest] -> do_lex([token.Asterisk, ..tokens], rest)
    ["/", ..rest] -> do_lex([token.Slash, ..tokens], rest)
    ["<", ..rest] -> do_lex([token.LT, ..tokens], rest)
    [">", ..rest] -> do_lex([token.GT, ..tokens], rest)
    ["\"", ..rest] -> lex_string(rest, string_builder.new(), tokens)
    [" ", ..rest] | ["\n", ..rest] | ["\r", ..rest] | ["\t", ..rest] ->
      do_lex(tokens, rest)
    [c, ..rest] -> {
      use <- bool.lazy_guard(when: is_digit(c), return: fn() {
        lex_digit(remaining)
      })
      use <- bool.lazy_guard(when: is_ident(c), return: fn() {
        lex_ident(remaining)
      })
      do_lex([token.Illegal(c), ..tokens], rest)
    }

    [] -> list.reverse(tokens)
  }
}

fn lex_string(remaining, builder, tokens) {
  case remaining {
    ["\"", ..rest] ->
      do_lex([token.String(string_builder.to_string(builder)), ..tokens], rest)

    [] ->
      [token.Illegal(string_builder.to_string(builder)), ..tokens]
      |> list.reverse()

    [c, ..rest] -> lex_string(rest, string_builder.append(builder, c), tokens)
  }
}

fn digit_length(graphemes) {
  predicate_length(graphemes, is_digit)
}

fn ident_length(graphemes) {
  predicate_length(graphemes, is_ident)
}

fn predicate_length(graphemes, predicate) {
  graphemes
  |> list.fold_until(0, fn(count, grapheme) {
    case predicate(grapheme) {
      True -> list.Continue(count + 1)
      False -> list.Stop(count)
    }
  })
}

const lower_a = 97

const lower_z = 122

const upper_a = 65

const upper_z = 90

const underscore = 95

fn is_ident(char) {
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
