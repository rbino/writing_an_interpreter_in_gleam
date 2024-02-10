import gleam/io
import monkey/repl

pub fn main() {
  io.println("Hello! This is the Monkey programming language!")
  io.println("Feel free to type in commands")
  repl.start()
}
