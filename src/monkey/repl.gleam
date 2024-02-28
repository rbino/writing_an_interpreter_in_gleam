import gleam/erlang
import gleam/io
import gleam/list
import gleam/result
import monkey/evaluator
import monkey/lexer
import monkey/obj
import monkey/parser

const prompt = ">> "

pub fn start() {
  loop()
}

fn loop() {
  let _ = {
    use line <- result.map(erlang.get_line(prompt))
    let tokens = lexer.lex(line)
    case parser.parse(tokens) {
      Ok(program) ->
        case evaluator.eval(program) {
          Ok(obj) -> io.println(obj.inspect(obj))
          Error(e) -> io.println(obj.inspect(e))
        }

      Error(errors) -> {
        io.println("Errors during parsing:")
        list.each(errors, fn(error) { io.println("  " <> error) })
      }
    }
  }

  loop()
}
