import gleeunit
import gleeunit/should
import gleam/list
import monkey/lexer
import monkey/parser

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn parse_test() {
  let input =
    "let x = 5;
let y = 10;
let foobar = 838383;
"

  let expected_identifiers = ["x", "y", "foobar"]

  let result =
    input
    |> lexer.lex()
    |> parser.parse()

  should.be_ok(result)

  let assert Ok(program) = result

  list.length(program)
  |> should.equal(list.length(expected_identifiers))

  list.zip(expected_identifiers, program)
  |> list.each(fn(pair) {
    let #(expected, node) = pair

    node
    |> should.equal(parser.Let(name: expected, value: Nil))
  })
}

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
