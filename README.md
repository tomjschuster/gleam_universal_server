# universal_server

A [Gleam](https://gleam.run/) implementation of the "Universal Server" demonstrated by Joe Armstrong in his blog post [My favorite Erlang Program](https://joearms.github.io/published/2013-11-21-My-favorite-erlang-program.html).

```gleam
import gleam/erlang/process.{type Subject}
import gleam/result.{try}
import universal_server

pub fn main() {
  use u_subject <- try(universal_server.start(True))
  use f_subject <- try(universal_server.become(u_subject, factorial_server))

  let assert Ok(120) = compute_factorial(f_subject, 5)
  let assert Ok(3_628_800) = compute_factorial(f_subject, 10)
  Ok(Nil)
}

fn factorial_server(subject: Subject(#(Subject(Int), Int))) {
  let #(reply_to, n) =
    process.new_selector()
    |> process.selecting(subject, fn(m) { m })
    |> process.select_forever()

  process.send(reply_to, factorial(n))

  factorial_server(subject)
}

fn compute_factorial(
  subject: Subject(#(Subject(Int), Int)),
  n: Int,
) -> Result(Int, Nil) {
  let reply_to = process.new_subject()
  process.send(subject, #(reply_to, n))
  process.receive(reply_to, 5000)
}

fn factorial(n: Int) -> Int {
  case n {
    0 -> 1
    n if n > 0 -> n * factorial(n - 1)
    _ -> panic as "cannot calculate negative factorial"
  }
}
```

## Development

```sh
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
