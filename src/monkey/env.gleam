import gleam/dict
import monkey/obj

pub type Env {
  Env(store: dict.Dict(String, obj.Object))
}

pub fn new() {
  Env(store: dict.new())
}

pub fn get(env: Env, name) {
  dict.get(env.store, name)
}

pub fn set(env: Env, name, value) {
  Env(store: dict.insert(env.store, name, value))
}
