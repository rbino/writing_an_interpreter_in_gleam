import gleam/list
import gleam/result
import monkey/token

pub type Program {
  List(Node)
}

pub type Node {
  Let(name: String, value: Nil)
  Return(value: Nil)
  Ident(String)
}

type Parser {
  Parser(remaining: List(token.Token), errors: List(String))
}

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

    _ -> Error(parser)
  }
}

fn parse_let_statement(parser: Parser) {
  case parser.remaining {
    [token.Ident(name), token.Assign, ..] -> {
      // TODO: right now we're skipping the expression
      use parser <- result.map(skip(parser, until: token.Semicolon))
      let node = Let(name: name, value: Nil)
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
  use parser <- result.map(skip(parser, until: token.Semicolon))
  let node = Return(value: Nil)
  #(node, parser)
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

fn add_unexpected_token_error(parser, expected token, got actual) {
  let expected = case token {
    token.Ident("") -> "an identifier"
    token.Int("") -> "an integer"
    token -> token.to_string(token)
  }

  let error = "Expected " <> expected <> " but got " <> token.to_string(actual)

  Parser(..parser, errors: [error, ..parser.errors])
}
