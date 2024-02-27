import gleam/erlang
import gleam/io
import gleam/list
import gleam/result
import monkey/ast
import monkey/lexer
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
        list.each(program, fn(statement) {
          statement
          |> ast.to_string()
          |> io.println()
        })

      Error(errors) -> {
        io.println("Errors during parsing:")
        list.each(errors, fn(error) { io.println("  " <> error) })
      }
    }
  }

  loop()
}
