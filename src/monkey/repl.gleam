import gleam/erlang
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import monkey/lexer

const prompt = ">> "

pub fn start() {
  loop()
}

fn loop() {
  let _ = {
    use line <- result.map(erlang.get_line(prompt))
    let tokens = lexer.lex(line)
    list.each(tokens, fn(token) {
      token
      |> string.inspect()
      |> io.println()
    })
  }

  loop()
}
