import gleeunit
import gleeunit/should
import gleam/dict
import gleam/list
import monkey/ast
import monkey/lexer
import monkey/parser

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn parse_error_test() {
  let input =
    "let x 5;
  let = 10;
  let 838383;
  let x ="

  let result =
    input
    |> lexer.lex()
    |> parser.parse()

  should.be_error(result)

  let assert Error([error_1, error_2, error_3, error_4]) = result
  should.equal(error_1, "Expected = but got 5")
  should.equal(error_2, "Expected an identifier but got =")
  should.equal(error_3, "Expected an identifier but got 838383")
  should.equal(error_4, "Unexpected end of file")
}

pub fn to_string_test() {
  let statement = ast.Let(name: "myVar", value: ast.Ident("anotherVar"))

  ast.to_string(statement)
  |> should.equal("let myVar = anotherVar")
}

pub fn identifier_expression_test() {
  expression_test("foobar;", ast.Ident("foobar"))
}

pub fn integer_expression_test() {
  expression_test("5;", ast.Int(5))
}

pub fn string_expression_test() {
  expression_test("\"foobar\";", ast.String("foobar"))
}

pub fn prefix_expression_test() {
  expression_test("-10;", ast.UnaryOp(ast.Negate, ast.Int(10)))
  expression_test("!foo", ast.UnaryOp(ast.BooleanNot, ast.Ident("foo")))
  expression_test("!true", ast.UnaryOp(ast.BooleanNot, ast.True))
}

pub fn infix_expression_test() {
  [
    #("+", ast.Add),
    #("-", ast.Sub),
    #("*", ast.Mul),
    #("/", ast.Div),
    #(">", ast.GT),
    #("<", ast.LT),
    #("==", ast.Eq),
    #("!=", ast.NotEq),
  ]
  |> list.each(fn(under_test) {
    let #(string_op, ast_op) = under_test
    let expected = ast.BinaryOp(ast.Int(5), ast_op, ast.Int(10))
    expression_test("5 " <> string_op <> " 10;", expected)
  })

  expression_test("true == true", ast.BinaryOp(ast.True, ast.Eq, ast.True))
  expression_test("false != true", ast.BinaryOp(ast.False, ast.NotEq, ast.True))
}

pub fn infix_expression_precedence_test() {
  [
    #("!-a", "(!(-a))"),
    #("a + b + c", "((a + b) + c)"),
    #("a + b - c", "((a + b) - c)"),
    #("a * b * c", "((a * b) * c)"),
    #("a * b / c", "((a * b) / c)"),
    #("a + b / c", "(a + (b / c))"),
    #("a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"),
    #("5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))"),
    #("5 < 4 != 3 > 4", "((5 < 4) != (3 > 4))"),
    #("3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"),
    #("!true", "(!true)"),
    #("3 > 5 == false", "((3 > 5) == false)"),
    #("1 + (2 + 3) + 4", "((1 + (2 + 3)) + 4)"),
    #("(5 + 5) * 2", "((5 + 5) * 2)"),
    #("2 / (5 + 5)", "(2 / (5 + 5))"),
    #("-(5 + 5)", "(-(5 + 5))"),
    #("!(true == true)", "(!(true == true))"),
  ]
  |> list.each(fn(under_test) {
    let #(input, parenthesized) = under_test
    expression_precedence_test(input, parenthesized)
  })
}

pub fn if_test() {
  let input = "if (x < y) { x }"
  let expected =
    ast.If(
      condition: ast.BinaryOp(ast.Ident("x"), ast.LT, ast.Ident("y")),
      consequence: ast.Block([ast.Ident("x")]),
    )
  expression_test(input, expected)

  let input = "if (z == true) { x } else { y }"
  let expected =
    ast.IfElse(
      condition: ast.BinaryOp(ast.Ident("z"), ast.Eq, ast.True),
      consequence: ast.Block([ast.Ident("x")]),
      alternative: ast.Block([ast.Ident("y")]),
    )
  expression_test(input, expected)
}

pub fn function_literal_test() {
  let input = "fn(a, b) { a + b }"
  let expected =
    ast.Fn(
      parameters: ["a", "b"],
      body: ast.Block([ast.BinaryOp(ast.Ident("a"), ast.Add, ast.Ident("b"))]),
    )
  expression_test(input, expected)

  let input = "fn(x) { x * y }"
  let expected =
    ast.Fn(
      parameters: ["x"],
      body: ast.Block([ast.BinaryOp(ast.Ident("x"), ast.Mul, ast.Ident("y"))]),
    )
  expression_test(input, expected)

  let input = "fn() { return 42; }"
  let expected =
    ast.Fn(parameters: [], body: ast.Block([ast.Return(ast.Int(42))]))
  expression_test(input, expected)
}

pub fn function_call_test() {
  let input = "foo(bar, 42 + baz)"
  let expected =
    ast.Call(function: ast.Ident("foo"), arguments: [
      ast.Ident("bar"),
      ast.BinaryOp(ast.Int(42), ast.Add, ast.Ident("baz")),
    ])
  expression_test(input, expected)

  let input = "fn(x, y){ return x * y }(10, 32)"
  let expected =
    ast.Call(
      function: ast.Fn(
        parameters: ["x", "y"],
        body: ast.Block([
          ast.Return(ast.BinaryOp(ast.Ident("x"), ast.Mul, ast.Ident("y"))),
        ]),
      ),
      arguments: [ast.Int(10), ast.Int(32)],
    )
  expression_test(input, expected)

  let input = "self()"
  let expected = ast.Call(function: ast.Ident("self"), arguments: [])
  expression_test(input, expected)
}

pub fn array_literal_test() {
  let input = "[1, 2 * 2, 3 + 3]"
  let expected =
    ast.Array([
      ast.Int(1),
      ast.BinaryOp(ast.Int(2), ast.Mul, ast.Int(2)),
      ast.BinaryOp(ast.Int(3), ast.Add, ast.Int(3)),
    ])
  expression_test(input, expected)
}

pub fn array_indexing_test() {
  let input = "myArray[1 + 1]"
  let expected =
    ast.Index(
      lhs: ast.Ident("myArray"),
      index: ast.BinaryOp(ast.Int(1), ast.Add, ast.Int(1)),
    )
  expression_test(input, expected)
}

pub fn hash_literal_test() {
  let input = "{\"one\": 1, \"two\": 2, \"three\": 3}"
  let expected =
    ast.Hash(
      [
        #(ast.String("one"), ast.Int(1)),
        #(ast.String("two"), ast.Int(2)),
        #(ast.String("three"), ast.Int(3)),
      ]
      |> dict.from_list(),
    )
  expression_test(input, expected)
}

pub fn empty_hash_literal_test() {
  let input = "{}"
  let expected = ast.Hash(dict.new())
  expression_test(input, expected)
}

pub fn expr_hash_literal_test() {
  let input = "{\"one\": 0 + 1, \"two\": 10 - 8, \"three\": 15 / 5}"
  let expected =
    ast.Hash(
      [
        #(
          ast.String("one"),
          ast.BinaryOp(lhs: ast.Int(0), op: ast.Add, rhs: ast.Int(1)),
        ),
        #(
          ast.String("two"),
          ast.BinaryOp(lhs: ast.Int(10), op: ast.Sub, rhs: ast.Int(8)),
        ),
        #(
          ast.String("three"),
          ast.BinaryOp(lhs: ast.Int(15), op: ast.Div, rhs: ast.Int(5)),
        ),
      ]
      |> dict.from_list(),
    )
  expression_test(input, expected)
}

fn expression_test(input, expected) {
  let result =
    input
    |> lexer.lex()
    |> parser.parse()

  should.be_ok(result)

  let assert Ok([statement]) = result

  statement
  |> should.equal(expected)
}

fn expression_precedence_test(input, parenthesized) {
  let result =
    input
    |> lexer.lex()
    |> parser.parse()

  should.be_ok(result)

  let assert Ok([expr]) = result
  expr
  |> ast.to_string()
  |> should.equal(parenthesized)
}
