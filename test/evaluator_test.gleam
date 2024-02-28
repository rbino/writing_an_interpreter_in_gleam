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
    let assert evaluator.TypeError(_) =
      input
      |> eval_error()
  })
}

pub fn eval_integer_expression_test() {
  [
    #("5", 5),
    #("10", 10),
    #("-5", -5),
    #("5 + 5 + 5 + 5 - 10", 10),
    #("2 * 2 * 2 * 2 * 2", 32),
    #("-50 + 100 + -50", 0),
    #("5 * 2 + 10", 20),
    #("5 + 2 * 10", 25),
    #("20 + 2 * -10", 0),
    #("50 / 2 * 2 + 10", 60),
    #("2 * (5 + 10)", 30),
    #("3 * 3 * 3 + 10", 37),
    #("3 * (3 * 3) + 10", 37),
    #("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50),
  ]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(obj.Int(expected))
  })

  ["5 + true", "!4 - 5", "true * false"]
  |> list.each(fn(input) {
    let assert evaluator.TypeError(_) =
      input
      |> eval_error()
  })
}

pub fn eval_boolean_expression_test() {
  [
    #("true", obj.True),
    #("false", obj.False),
    #("1 < 2", obj.True),
    #("1 > 2", obj.False),
    #("1 < 1", obj.False),
    #("1 > 1", obj.False),
    #("1 == 1", obj.True),
    #("1 != 1", obj.False),
    #("1 == 2", obj.False),
    #("1 != 2", obj.True),
  ]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(expected)
  })

  ["true < 5", "false > 42", "true < false"]
  |> list.each(fn(input) {
    let assert evaluator.TypeError(_) =
      input
      |> eval_error()
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
