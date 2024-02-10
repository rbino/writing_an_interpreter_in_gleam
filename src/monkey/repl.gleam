import gleam/erlang
import gleam/io
import gleam/iterator
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
    let iter =
      line
      |> lexer.new()
      |> lexer.to_iterator()
    use token <- iterator.each(iter)

    token
    |> string.inspect()
    |> io.println()
  }

  loop()
}
