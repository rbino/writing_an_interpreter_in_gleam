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
  expression_test("-10;", ast.Prefix(op: ast.Minus, rhs: ast.Int(10)))
  expression_test("!foo", ast.Prefix(op: ast.Bang, rhs: ast.Ident("foo")))
}

pub fn infix_expression_test() {
  [
    #("+", ast.Plus),
    #("-", ast.Minus),
    #("*", ast.Asterisk),
    #("/", ast.Slash),
    #(">", ast.GT),
    #("<", ast.LT),
    #("==", ast.Eq),
    #("!=", ast.NotEq),
  ]
  |> list.each(fn(under_test) {
    let #(string_op, ast_op) = under_test
    let expected = ast.Infix(lhs: ast.Int(5), op: ast_op, rhs: ast.Int(10))
    expression_test("5 " <> string_op <> " 10;", expected)
  })
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
