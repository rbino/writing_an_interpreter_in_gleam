import gleam/list
import monkey/token

pub type Program {
  List(Node)
}

pub type Node {
  Let(name: String, value: Nil)
  Ident(String)
}

pub fn parse(tokens) {
  do_parse([], tokens)
}

fn do_parse(program, remaining_tokens) {
  case remaining_tokens {
    [token.Eof] | [] -> list.reverse(program)
    [_token, ..rest] ->
      case parse_statement(remaining_tokens) {
        Ok(#(node, rest)) -> do_parse([node, ..program], rest)
        Error(Nil) -> do_parse(program, rest)
      }
  }
}

fn parse_statement(tokens) {
  case tokens {
    [token.Let, ..rest] -> parse_let_statement(rest)
    _ -> Error(Nil)
  }
}

fn parse_let_statement(tokens) {
  case tokens {
    [token.Ident(name), token.Assign, ..rest] -> {
      // TODO: right now we're skipping the expression
      let rest = skip(rest, until: token.Semicolon)
      let node = Let(name: name, value: Nil)
      Ok(#(node, rest))
    }
    _ -> Error(Nil)
  }
}

fn skip(tokens, until target_token) {
  case tokens {
    [token, ..rest] if token == target_token -> rest
    [_token, ..rest] -> skip(rest, target_token)
    [] -> todo
  }
}
