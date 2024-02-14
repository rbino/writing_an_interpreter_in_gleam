import gleam/int
import gleam/list
import gleam/result
import monkey/token

pub type Program {
  List(Node)
}

pub type Node {
  Let(name: String, value: Node)
  Return(value: Node)
  Ident(ident: String)
  Int(value: Int)
}

type Parser {
  Parser(remaining: List(token.Token), errors: List(String))
}

const prec_lowest = 1

const prec_equals = 2

const prec_lessgreater = 3

const prec_sum = 4

const prec_product = 5

const prec_prefix = 6

const prec_call = 7

pub fn parse(tokens) {
  do_parse(Parser(tokens, []), [])
}

fn do_parse(parser: Parser, program) {
  case parser.remaining {
    [token.Eof] | [] ->
      case parser.errors {
        [] -> Ok(list.reverse(program))
        errors -> Error(list.reverse(errors))
      }

    [token, ..] ->
      case parse_statement(parser, token) {
        Ok(#(node, parser)) -> do_parse(parser, [node, ..program])

        Error(parser) -> {
          parser
          |> advance()
          |> do_parse(program)
        }
      }
  }
}

fn parse_statement(parser: Parser, token) {
  case token {
    token.Let -> {
      parser
      |> advance()
      |> parse_let_statement()
    }

    token.Return -> {
      parser
      |> advance()
      |> parse_return_statement()
    }

    _ -> parse_expression(parser, prec_lowest)
  }
}

fn parse_let_statement(parser: Parser) {
  case parser.remaining {
    [token.Ident(name), token.Assign, ..] -> {
      let parser = advance_n(parser, 2)
      use #(expr, parser) <- result.map(parse_expression(parser, prec_lowest))
      let node = Let(name: name, value: expr)
      #(node, parser)
    }

    [token.Ident(_), token, ..] -> {
      parser
      |> add_unexpected_token_error(expected: token.Assign, got: token)
      |> Error()
    }

    [token, ..] -> {
      parser
      |> add_unexpected_token_error(expected: token.Ident(""), got: token)
      |> Error()
    }

    [] -> {
      parser
      |> add_unexpected_token_error(expected: token.Ident(""), got: token.Eof)
      |> Error()
    }
  }
}

fn parse_return_statement(parser: Parser) {
  use #(expr, parser) <- result.map(parse_expression(parser, prec_lowest))
  let node = Return(value: expr)
  #(node, parser)
}

fn parse_expression(parser: Parser, _prec) {
  case parser.remaining {
    [token.Eof] | [] ->
      parser
      |> add_unexpected_eof_error()
      |> Error()

    [token, ..] -> {
      use #(lhs, parser) <- result.map(parse_prefix(parser, token))
      #(lhs, consume_optional_semicolon(parser))
    }
  }
}

fn parse_prefix(parser: Parser, token) {
  case token {
    token.Ident(value) -> Ok(#(Ident(value), advance(parser)))
    token.Int(value) -> Ok(#(Int(value), advance(parser)))

    _ -> {
      use parser <- result.then(skip(parser, until: token.Semicolon))
      Error(parser)
    }
  }
}

fn consume_optional_semicolon(parser: Parser) {
  case parser.remaining {
    [token.Semicolon, ..] -> advance(parser)
    _ -> parser
  }
}

fn skip(parser: Parser, until target_token) {
  case parser.remaining {
    [token, ..] if token == target_token -> Ok(parser)
    [_token, ..] -> {
      parser
      |> advance()
      |> skip(until: target_token)
    }
    [] ->
      parser
      |> add_unexpected_token_error(expected: target_token, got: token.Eof)
      |> Error()
  }
}

fn advance(parser) {
  Parser(..parser, remaining: list.drop(parser.remaining, 1))
}

fn advance_n(parser, n) {
  case n {
    0 -> parser
    n -> advance_n(parser, n - 1)
  }
}

fn add_unexpected_eof_error(parser) {
  let error = "Unexpected EOF"
  Parser(..parser, errors: [error, ..parser.errors])
}

fn add_unexpected_token_error(parser, expected token, got actual) {
  let expected = case token {
    token.Ident(_) -> "an identifier"
    token.Int(_) -> "an integer"
    token -> token.to_string(token)
  }

  let error = "Expected " <> expected <> " but got " <> token.to_string(actual)

  Parser(..parser, errors: [error, ..parser.errors])
}

pub fn to_string(node) {
  case node {
    Let(name: name, value: value) ->
      "let " <> name <> " = " <> to_string(value) <> ";"
    Return(value) -> "return " <> to_string(value) <> ";"
    Ident(value) -> value
    Int(value) -> int.to_string(value)
  }
}
