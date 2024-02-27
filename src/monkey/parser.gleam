import gleam/bool
import gleam/list
import gleam/result
import monkey/ast
import monkey/token

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
    token.Let ->
      parser
      |> advance()
      |> parse_let_statement()

    token.Return ->
      parser
      |> advance()
      |> parse_return_statement()

    _ -> parse_expression(parser, prec_lowest)
  }
}

fn parse_let_statement(parser: Parser) {
  case parser.remaining {
    [token.Ident(name), token.Assign, ..] -> {
      let parser = advance_n(parser, 2)
      use #(expr, parser) <- result.map(parse_expression(parser, prec_lowest))
      let node = ast.Let(name: name, value: expr)
      #(node, consume_optional_semicolon(parser))
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
  let node = ast.Return(value: expr)
  #(node, consume_optional_semicolon(parser))
}

fn parse_expression(parser: Parser, base_prec) {
  case parser.remaining {
    [token.Eof] | [] ->
      parser
      |> add_unexpected_eof_error()
      |> Error()

    [token, ..] -> {
      let parser = advance(parser)
      use #(lhs, parser) <- result.try(parse_prefix(parser, token))
      use #(expr, parser) <- result.map(parse_infix(parser, lhs, base_prec))
      #(expr, consume_optional_semicolon(parser))
    }
  }
}

fn parse_prefix(parser: Parser, token) {
  case token {
    token.Ident(value) -> Ok(#(ast.Ident(value), parser))
    token.Int(value) -> Ok(#(ast.Int(value), parser))
    token.True -> Ok(#(ast.True, parser))
    token.False -> Ok(#(ast.False, parser))
    token.Minus -> parse_prefix_expression(parser, ast.Minus)
    token.Bang -> parse_prefix_expression(parser, ast.Bang)

    token.LParen -> {
      use #(expr, parser) <- result.try(parse_expression(parser, prec_lowest))
      use parser <- result.map(expect(parser, token.RParen))
      #(expr, parser)
    }

    token.If -> parse_if_expression(parser)
    token.Fn -> parse_function_literal(parser)

    _ -> {
      use parser <- result.then(skip(parser, until: token.Semicolon))
      Error(parser)
    }
  }
}

fn parse_prefix_expression(parser: Parser, op) {
  use #(rhs, parser) <- result.map(parse_expression(parser, prec_prefix))
  #(op(rhs), parser)
}

fn parse_if_expression(parser: Parser) {
  use parser <- result.try(expect(parser, token.LParen))
  use #(condition, parser) <- result.try(parse_expression(parser, prec_lowest))
  use parser <- result.try(expect(parser, token.RParen))
  use #(consequence, parser) <- result.try(parse_block(parser))
  let parser: Parser = parser
  case parser.remaining {
    [token.Else, ..] -> {
      let parser = advance(parser)
      use #(alternative, parser) <- result.map(parse_block(parser))
      let node =
        ast.IfElse(
          condition: condition,
          consequence: consequence,
          alternative: alternative,
        )
      #(node, parser)
    }

    _ -> {
      let node = ast.If(condition: condition, consequence: consequence)
      Ok(#(node, parser))
    }
  }
}

fn parse_function_literal(parser: Parser) {
  use parser <- result.try(expect(parser, token.LParen))
  use #(parameters, parser) <- result.try(parse_function_parameters(parser, []))
  use #(body, parser) <- result.map(parse_block(parser))
  let node = ast.Fn(parameters: parameters, body: body)
  #(node, parser)
}

fn parse_function_parameters(parser: Parser, params) {
  case parser.remaining {
    [token.Ident(param), token.Comma, ..] -> {
      parse_function_parameters(advance_n(parser, 2), [param, ..params])
    }

    [token.Ident(param), token.RParen, ..] ->
      Ok(#(list.reverse([param, ..params]), advance_n(parser, 2)))

    [token.RParen, ..] -> Ok(#(params, advance(parser)))

    [token.Eof] | [] ->
      parser
      |> add_unexpected_eof_error()
      |> Error()

    [token, ..] ->
      parser
      |> add_unexpected_token_error(token.Ident(""), token)
      |> Error()
  }
}

fn parse_infix(parser: Parser, lhs, base_prec) {
  let next_prec = peek_precedence(parser)
  use <- bool.guard(when: base_prec >= next_prec, return: Ok(#(lhs, parser)))
  case parser.remaining {
    [token, ..] -> {
      let op = case token {
        token.Eq -> ast.Eq
        token.NotEq -> ast.NotEq
        token.LT -> ast.LT
        token.GT -> ast.GT
        token.Plus -> ast.Add
        token.Minus -> ast.Subtract
        token.Asterisk -> ast.Multiply
        token.Slash -> ast.Divide
        // We can safely panic here: peek_precedence returns prec_lowest
        // for all tokens which are not valid infix tokens, so we should
        // never get past bool.guard in those cases
        _ -> panic
      }

      let parser = advance(parser)
      use #(rhs, parser) <- result.try(parse_expression(parser, next_prec))
      let node = op(lhs, rhs)
      parse_infix(parser, node, base_prec)
    }

    [] ->
      parser
      |> add_unexpected_eof_error()
      |> Error()
  }
}

fn parse_block(parser: Parser) {
  use parser <- result.try(expect(parser, token.LBrace))
  do_parse_block(parser, [])
}

fn do_parse_block(parser: Parser, statements) {
  case parser.remaining {
    [token.Eof] | [] ->
      parser
      |> add_unexpected_eof_error()
      |> Error()

    [token.RBrace, ..] -> {
      let block =
        statements
        |> list.reverse()
        |> ast.Block()

      Ok(#(block, advance(parser)))
    }

    [token, ..] -> {
      use #(statement, parser) <- result.try(parse_statement(parser, token))
      do_parse_block(parser, [statement, ..statements])
    }
  }
}

fn peek_precedence(parser: Parser) {
  case parser.remaining {
    [token.Eq, ..] -> prec_equals
    [token.NotEq, ..] -> prec_equals
    [token.LT, ..] -> prec_lessgreater
    [token.GT, ..] -> prec_lessgreater
    [token.Plus, ..] -> prec_sum
    [token.Minus, ..] -> prec_sum
    [token.Asterisk, ..] -> prec_product
    [token.Slash, ..] -> prec_product
    _ -> prec_lowest
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
    n -> advance_n(advance(parser), n - 1)
  }
}

fn expect(parser: Parser, expected) {
  case parser.remaining {
    [token, ..] if token == expected -> Ok(advance(parser))
    [token, ..] -> {
      parser
      |> advance()
      |> add_unexpected_token_error(expected, token)
      |> Error()
    }
    [token.Eof, ..] | [] -> {
      parser
      |> advance()
      |> add_unexpected_eof_error()
      |> Error()
    }
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
