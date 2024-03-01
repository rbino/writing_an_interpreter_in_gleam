import gleeunit
import gleeunit/should
import gleam/list
import monkey/ast
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
    let assert obj.Error(obj.TypeError(_)) =
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
    let assert obj.Error(obj.TypeError(_)) =
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
    #("true == true", obj.True),
    #("false == false", obj.True),
    #("true == false", obj.False),
    #("true != false", obj.True),
    #("false != true ", obj.True),
    #("(1 < 2) == true", obj.True),
    #("(1 < 2) == false", obj.False),
    #("(1 > 2) == true", obj.False),
    #("(1 > 2) == false", obj.True),
  ]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(expected)
  })

  ["true < 5", "false > 42", "true < false"]
  |> list.each(fn(input) {
    let assert obj.Error(obj.TypeError(_)) =
      input
      |> eval_error()
  })
}

pub fn eval_if_else_expression_test() {
  [
    #("if (true) { 10 }", obj.Int(10)),
    #("if (false) { 10 }", obj.Null),
    #("if (1) { 10 }", obj.Int(10)),
    #("if (1 < 2) { 10 }", obj.Int(10)),
    #("if (1 > 2) { 10 }", obj.Null),
    #("if (1 > 2) { 10 } else { 20 }", obj.Int(20)),
    #("if (1 < 2) { 10 } else { 20 }", obj.Int(10)),
  ]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(expected)
  })
}

pub fn eval_return_test() {
  [
    #("return 10;", obj.Int(10)),
    #("return 10; 9;", obj.Int(10)),
    #("return 2 * 5; 9;", obj.Int(10)),
    #("9; return 2 * 5; 9;", obj.Int(10)),
  ]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(expected)
  })

  let input =
    "
  if (10 > 1) {
    if (10 > 1) {
      return 10;
    }

    return 1;
  }
  "

  input
  |> eval()
  |> should.equal(obj.Int(10))
}

pub fn eval_let_test() {
  [
    #("let a = 5; a;", obj.Int(5)),
    #("let a = 5 * 5; a;", obj.Int(25)),
    #("let a = 5; let b = a; b;", obj.Int(5)),
    #("let a = 5; let b = a; let c = a + b + 5; c;", obj.Int(15)),
  ]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(expected)
  })

  let assert obj.Error(obj.UnknownIdentifierError(_)) =
    "foobar"
    |> eval_error()
}

pub fn function_literal_test() {
  let input = "fn(x) { x + 2; }"
  let assert obj.Fn(params, body, _env) = eval(input)

  params
  |> should.equal(["x"])

  body
  |> should.equal(
    ast.Block([ast.BinaryOp(ast.Ident("x"), ast.Add, ast.Int(2))]),
  )
}

fn eval(input) {
  let result =
    input
    |> lexer.lex()
    |> parser.parse()

  let assert Ok(program) = result
  let env = obj.new_env()
  let assert Ok(#(obj, _env)) = evaluator.eval(program, env)
  obj
}

fn eval_error(input) {
  let result =
    input
    |> lexer.lex()
    |> parser.parse()

  let assert Ok(program) = result
  let env = obj.new_env()
  let assert Error(#(err, _env)) = evaluator.eval(program, env)
  err
}
