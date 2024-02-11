import gleeunit
import gleeunit/should
import gleam/list
import monkey/lexer
import monkey/parser

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn next_token_test() {
  let input =
    "let x = 5;
let y = 10;
let foobar = 838383;
"

  let expected_identifiers = ["x", "y", "foobar"]

  let program =
    input
    |> lexer.lex()
    |> parser.parse()

  list.length(program)
  |> should.equal(list.length(expected_identifiers))

  list.zip(expected_identifiers, program)
  |> list.each(fn(pair) {
    let #(expected, node) = pair

    node
    |> should.equal(parser.Let(name: expected, value: Nil))
  })
}
