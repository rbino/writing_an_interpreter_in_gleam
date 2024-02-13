import gleeunit
import gleeunit/should
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
  let statement = parser.Let(name: "myVar", value: parser.Ident("anotherVar"))

  parser.to_string(statement)
  |> should.equal("let myVar = anotherVar;")
}

pub fn identifier_expression_test() {
  let input = "foobar;"

  let result =
    input
    |> lexer.lex()
    |> parser.parse()

  should.be_ok(result)

  let assert Ok([statement]) = result

  statement
  |> should.equal(parser.Ident("foobar"))
}
