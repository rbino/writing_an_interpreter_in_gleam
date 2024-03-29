import gleeunit
import gleeunit/should
import gleam/dict
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

pub fn string_test() {
  "\"Hello, world!\""
  |> eval()
  |> should.equal(obj.String("Hello, world!"))

  "\"Hello,\" + \" \" + \"world!\""
  |> eval()
  |> should.equal(obj.String("Hello, world!"))
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
    #("let a = 5; if (true) { let a = 7; } a;", obj.Int(5)),
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

pub fn function_application_test() {
  [
    #("let identity = fn(x) { x; }; identity(5);", obj.Int(5)),
    #("let identity = fn(x) { return x; }; identity(5);", obj.Int(5)),
    #("let double = fn(x) { x * 2; }; double(5);", obj.Int(10)),
    #("let add = fn(x, y) { x + y; }; add(5, 5);", obj.Int(10)),
    #("let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", obj.Int(20)),
    #("fn(x) { x; }(5)", obj.Int(5)),
  ]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(expected)
  })

  let assert obj.Error(obj.BadFunctionError(_)) =
    "let x = 1; x(3)"
    |> eval_error()

  let assert obj.Error(obj.BadArityError(_)) =
    "let f = fn(x) { x }; f()"
    |> eval_error()

  let assert obj.Error(obj.BadArityError(_)) =
    "let f = fn(x, y) { x + y }; f(1, 2, 3)"
    |> eval_error()
}

pub fn closures_test() {
  let input =
    "
  let newAdder = fn(x) {
    fn(y) { x + y };
  };
  
  let addTwo = newAdder(2);
  addTwo(2);   
  "

  input
  |> eval()
  |> should.equal(obj.Int(4))
}

pub fn builtin_len_test() {
  [
    #("len(\"\")", obj.Int(0)),
    #("len(\"four\")", obj.Int(4)),
    #("len(\"hello world\")", obj.Int(11)),
    #("len([1, 2, 3])", obj.Int(3)),
    #("first([1, 2, 3])", obj.Int(1)),
    #("rest([1, 2, 3])", obj.Array([obj.Int(2), obj.Int(3)])),
    #("last([1, 2, 3])", obj.Int(3)),
    #("first(rest([1, 2, 3]))", obj.Int(2)),
    #("last(rest([1, 2, 3]))", obj.Int(3)),
    #("first([])", obj.Null),
    #("last([])", obj.Null),
    #("rest([])", obj.Null),
    #("rest(rest([1]))", obj.Null),
  ]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(expected)
  })

  ["len(1)", "len(true)", "first(1)", "last(\"foo\")", "rest(true)"]
  |> list.each(fn(under_test) {
    let assert obj.Error(obj.TypeError(_)) =
      under_test
      |> eval_error()
  })

  ["len(\"foo\", \"bar\")", "len([], [])", "first([], [])", "last([], [])"]
  |> list.each(fn(under_test) {
    let assert obj.Error(obj.BadArityError(_)) =
      under_test
      |> eval_error()
  })
}

pub fn array_literal_test() {
  "[1, 2 * 2, 3 + 3, \"foo\"]"
  |> eval()
  |> should.equal(
    obj.Array([obj.Int(1), obj.Int(4), obj.Int(6), obj.String("foo")]),
  )
}

pub fn array_indexing_test() {
  [
    #("[1, 2, 3][0]", obj.Int(1)),
    #("[1, 2, 3][1]", obj.Int(2)),
    #("[1, 2, 3][2]", obj.Int(3)),
    #("let i = 0; [1][i]", obj.Int(1)),
    #("[1, 2, 3][1 + 1]", obj.Int(3)),
    #("let myArray = [1, 2, 3]; myArray[2];", obj.Int(3)),
    #(
      "let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];",
      obj.Int(6),
    ),
    #("let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i];", obj.Int(2)),
    #("[1, 2, 3][3]", obj.Null),
    #("[1, 2, 3][-1]", obj.Null),
  ]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(expected)
  })
}

pub fn hash_eval_test() {
  let input =
    "let two = \"two\";
 {
   \"one\": 10 - 9,
   two: 1 + 1,
   \"thr\" + \"ee\": 6 / 2,
   4: 4,
   true: 5,
   false: 6
 }
"

  let assert obj.Hash(elements) = eval(input)

  [
    #(obj.String("one"), obj.Int(1)),
    #(obj.String("two"), obj.Int(2)),
    #(obj.String("three"), obj.Int(3)),
    #(obj.Int(4), obj.Int(4)),
    #(obj.True, obj.Int(5)),
    #(obj.False, obj.Int(6)),
  ]
  |> list.each(fn(expected) {
    let #(key, value) = expected

    dict.get(elements, key)
    |> should.equal(Ok(value))
  })
}

pub fn hash_indexing_test() {
  [
    #("{\"foo\": 5}[\"foo\"]", obj.Int(5)),
    #("{\"foo\": 5}[\"bar\"]", obj.Null),
    #("let key = \"foo\"; {\"foo\": 5}[key]", obj.Int(5)),
    #("{}[\"foo\"]", obj.Null),
    #("{5: 5}[5]", obj.Int(5)),
    #("{true: 5}[true]", obj.Int(5)),
    #("{false: 5}[false]", obj.Int(5)),
    #("let f = fn() { 42 }; {f: 5}[f]", obj.Int(5)),
    #("let f = fn() { 42 }; let g = fn() { 42 }; {f: 5}[g]", obj.Null),
  ]
  |> list.each(fn(under_test) {
    let #(input, expected) = under_test

    input
    |> eval()
    |> should.equal(expected)
  })
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
