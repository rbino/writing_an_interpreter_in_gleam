import gleeunit
import gleeunit/should
import gleam/list
import monkey/evaluator
import monkey/lexer
import monkey/obj
import monkey/parser

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn eval_integer_test() {
  [#("5", 5), #("10", 10)]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(obj.Int(expected))
  })
}

pub fn eval_boolean_test() {
  [#("true", obj.True), #("false", obj.False)]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(expected)
  })
}

pub fn eval_bang_operator_test() {
  [
    #("!true", obj.False),
    #("!false", obj.True),
    #("!5", obj.False),
    #("!!true", obj.True),
    #("!!false", obj.False),
    #("!!5", obj.True),
  ]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(expected)
  })
}

pub fn eval_minus_operator_test() {
  [#("-5", -5), #("--7", 7)]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(obj.Int(expected))
  })

  ["-true", "-false"]
  |> list.each(fn(input) {
    input
    |> eval_error()
    |> should.equal(evaluator.ArithmeticError)
  })
}

fn eval(input) {
  let result =
    input
    |> lexer.lex()
    |> parser.parse()

  let assert Ok(program) = result
  let assert Ok(obj) = evaluator.eval(program)
  obj
}

fn eval_error(input) {
  let result =
    input
    |> lexer.lex()
    |> parser.parse()

  let assert Ok(program) = result
  let assert Error(err) = evaluator.eval(program)
  err
}
