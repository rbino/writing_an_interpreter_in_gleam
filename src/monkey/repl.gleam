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
  obj.new_env()
  |> loop()
}

fn loop(env) {
  let new_env = {
    use line <- result.try(result.nil_error(erlang.get_line(prompt)))
    let tokens = lexer.lex(line)
    case parser.parse(tokens) {
      Ok(program) ->
        case evaluator.eval(program, env) {
          Ok(#(obj, new_env)) -> {
            io.println(obj.inspect(obj))
            Ok(new_env)
          }
          Error(#(err, new_env)) -> {
            io.println(obj.inspect(err))
            Ok(new_env)
          }
        }

      Error(errors) -> {
        io.println("Errors during parsing:")
        list.each(errors, fn(error) { io.println("  " <> error) })
        Error(Nil)
      }
    }
  }

  case new_env {
    Ok(new_env) -> loop(new_env)
    Error(Nil) -> loop(env)
  }
}
