import gleeunit
import gleeunit/should
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
  let y = 6"

  let result =
    input
    |> lexer.lex()
    |> parser.parse()

  should.be_error(result)

  let assert Error([error_1, error_2, error_3, error_4]) = result
  should.equal(error_1, "Expected = but got 5")
  should.equal(error_2, "Expected an identifier but got =")
  should.equal(error_3, "Expected an identifier but got 838383")
  should.equal(error_4, "Expected ; but got EOF")
}

pub fn to_string_test() {
  let statement = ast.Let(name: "myVar", value: ast.Ident("anotherVar"))

  ast.to_string(statement)
  |> should.equal("let myVar = anotherVar;")
}

pub fn identifier_expression_test() {
  expression_test("foobar;", ast.Ident("foobar"))
}

pub fn integer_expression_test() {
  expression_test("5;", ast.Int(5))
}

pub fn prefix_expression_test() {
  expression_test("-10;", ast.Minus(rhs: ast.Int(10)))
  expression_test("!foo", ast.Bang(rhs: ast.Ident("foo")))
  expression_test("!true", ast.Bang(rhs: ast.True))
}

pub fn infix_expression_test() {
  [
    #("+", ast.Add),
    #("-", ast.Subtract),
    #("*", ast.Multiply),
    #("/", ast.Divide),
    #(">", ast.GT),
    #("<", ast.LT),
    #("==", ast.Eq),
    #("!=", ast.NotEq),
  ]
  |> list.each(fn(under_test) {
    let #(string_op, ast_op) = under_test
    let expected = ast_op(ast.Int(5), ast.Int(10))
    expression_test("5 " <> string_op <> " 10;", expected)
  })

  expression_test("true == true", ast.Eq(lhs: ast.True, rhs: ast.True))
  expression_test("false != true", ast.NotEq(lhs: ast.False, rhs: ast.True))
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
      condition: ast.LT(lhs: ast.Ident("x"), rhs: ast.Ident("y")),
      consequence: ast.Block([ast.Ident("x")]),
    )
  expression_test(input, expected)

  let input = "if (z == true) { x } else { y }"
  let expected =
    ast.IfElse(
      condition: ast.Eq(lhs: ast.Ident("z"), rhs: ast.True),
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
      body: ast.Block([ast.Add(lhs: ast.Ident("a"), rhs: ast.Ident("b"))]),
    )
  expression_test(input, expected)

  let input = "fn(x) { x * y }"
  let expected =
    ast.Fn(
      parameters: ["x"],
      body: ast.Block([ast.Multiply(lhs: ast.Ident("x"), rhs: ast.Ident("y"))]),
    )
  expression_test(input, expected)

  let input = "fn() { return 42; }"
  let expected =
    ast.Fn(parameters: [], body: ast.Block([ast.Return(ast.Int(42))]))
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
