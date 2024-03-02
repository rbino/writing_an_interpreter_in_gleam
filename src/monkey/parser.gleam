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

const prec_index = 8

pub fn parse(tokens) {
  do_parse(Parser(tokens, []), [])
}

fn do_parse(parser: Parser, program) {
  case parser.remaining {
    [token, ..] ->
      case parse_statement(parser, token) {
        Ok(#(node, parser)) -> do_parse(parser, [node, ..program])

        Error(parser) -> {
          parser
          |> skip(until: token.Semicolon)
          |> do_parse(program)
        }
      }

    [] ->
      case parser.errors {
        [] -> Ok(list.reverse(program))
        errors -> Error(list.reverse(errors))
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
      |> add_unexpected_token_error(expected: "=", got: token)
      |> Error()
    }

    [token, ..] -> {
      parser
      |> add_unexpected_token_error(expected: "an identifier", got: token)
      |> Error()
    }

    [] -> {
      parser
      |> add_unexpected_eof_error()
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
    [token, ..] -> {
      let parser = advance(parser)
      use #(lhs, parser) <- result.try(parse_prefix(parser, token))
      use #(expr, parser) <- result.map(parse_infix(parser, lhs, base_prec))
      #(expr, consume_optional_semicolon(parser))
    }

    [] ->
      parser
      |> add_unexpected_eof_error()
      |> Error()
  }
}

fn parse_prefix(parser: Parser, token) {
  case token {
    token.Ident(value) -> Ok(#(ast.Ident(value), parser))
    token.Int(value) -> Ok(#(ast.Int(value), parser))
    token.String(value) -> Ok(#(ast.String(value), parser))
    token.True -> Ok(#(ast.True, parser))
    token.False -> Ok(#(ast.False, parser))
    token.Minus -> parse_unary_op(parser, ast.Negate)
    token.Bang -> parse_unary_op(parser, ast.BooleanNot)

    token.LParen -> {
      use #(expr, parser) <- result.try(parse_expression(parser, prec_lowest))
      use parser <- result.map(expect(parser, token.RParen))
      #(expr, parser)
    }

    token.If -> parse_if_expression(parser)
    token.Fn -> parse_function_literal(parser)
    token.LBracket -> {
      let result = parse_expression_list(parser, [], token.RBracket)
      use #(exprs, parser) <- result.map(result)
      #(ast.Array(exprs), parser)
    }
    token ->
      parser
      |> add_unexpected_token_error("an expression", token)
      |> Error()
  }
}

fn parse_unary_op(parser: Parser, op) {
  use #(rhs, parser) <- result.map(parse_expression(parser, prec_prefix))
  #(ast.UnaryOp(op: op, rhs: rhs), parser)
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

    [token, ..] ->
      parser
      |> add_unexpected_token_error("an identifier", token)
      |> Error()

    [] ->
      parser
      |> add_unexpected_eof_error()
      |> Error()
  }
}

fn parse_infix(parser: Parser, lhs, base_prec) {
  let next_prec = peek_precedence(parser)
  use <- bool.guard(when: base_prec >= next_prec, return: Ok(#(lhs, parser)))
  case parser.remaining {
    [token.LParen, ..] -> {
      let result = parse_expression_list(advance(parser), [], token.RParen)
      use #(arguments, parser) <- result.try(result)
      let node = ast.Call(function: lhs, arguments: arguments)
      parse_infix(parser, node, base_prec)
    }

    [token.LBracket, ..] -> {
      let result = parse_expression(advance(parser), prec_lowest)
      use #(index, parser) <- result.try(result)
      use parser <- result.try(expect(parser, token.RBracket))
      let node = ast.Index(lhs: lhs, index: index)
      parse_infix(parser, node, base_prec)
    }

    [token, ..] -> {
      let op = case token {
        token.Eq -> ast.Eq
        token.NotEq -> ast.NotEq
        token.LT -> ast.LT
        token.GT -> ast.GT
        token.Plus -> ast.Add
        token.Minus -> ast.Sub
        token.Asterisk -> ast.Mul
        token.Slash -> ast.Div
        // We can safely panic here: peek_precedence returns prec_lowest
        // for all tokens which are not valid infix tokens, so we should
        // never get past bool.guard in those cases
        _ -> panic
      }

      let parser = advance(parser)
      use #(rhs, parser) <- result.try(parse_expression(parser, next_prec))
      let node = ast.BinaryOp(lhs: lhs, op: op, rhs: rhs)
      parse_infix(parser, node, base_prec)
    }

    [] ->
      parser
      |> add_unexpected_eof_error()
      |> Error()
  }
}

fn parse_expression_list(parser: Parser, elems, end) {
  case parser.remaining {
    [token, ..] if token == end -> {
      Ok(#(list.reverse(elems), advance(parser)))
    }

    [] ->
      parser
      |> add_unexpected_eof_error()
      |> Error()

    _ -> {
      use #(elem, parser) <- result.try(parse_expression(parser, prec_lowest))
      case parser.remaining {
        [token.Comma, ..] ->
          parse_expression_list(advance(parser), [elem, ..elems], end)

        [token, ..] if token == end -> {
          Ok(#(list.reverse([elem, ..elems]), advance(parser)))
        }

        [token, ..] ->
          parser
          |> add_unexpected_token_error(", or ]", token)
          |> Error()

        [] ->
          parser
          |> add_unexpected_eof_error()
          |> Error()
      }
    }
  }
}

fn parse_block(parser: Parser) {
  use parser <- result.try(expect(parser, token.LBrace))
  do_parse_block(parser, [])
}

fn do_parse_block(parser: Parser, statements) {
  case parser.remaining {
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

    [] ->
      parser
      |> add_unexpected_eof_error()
      |> Error()
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
    [token.LParen, ..] -> prec_call
    [token.LBracket, ..] -> prec_index
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
    [token, ..] if token == target_token -> advance(parser)
    [_token, ..] -> {
      parser
      |> advance()
      |> skip(until: target_token)
    }
    [] -> parser
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
      |> add_unexpected_token_error(token.to_string(expected), token)
      |> Error()
    }
    [] -> {
      parser
      |> advance()
      |> add_unexpected_eof_error()
      |> Error()
    }
  }
}

fn add_unexpected_eof_error(parser) {
  let error = "Unexpected end of file"
  Parser(..parser, errors: [error, ..parser.errors])
}

fn add_unexpected_token_error(parser, expected token, got actual) {
  let error = "Expected " <> token <> " but got " <> token.to_string(actual)

  Parser(..parser, errors: [error, ..parser.errors])
}
