import gleam/erlang/process.{type Subject}
import gleeunit
import gleeunit/should
import universal_server

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn universal_server_test() {
  let reply_to = process.new_subject()

  let universal_subject =
    universal_server.start(True)
    |> should.be_ok()

  let concrete_subject =
    universal_server.become(universal_subject, factorial_server)

  should.equal(
    process.subject_owner(universal_subject),
    process.subject_owner(concrete_subject),
  )

  process.send(concrete_subject, Factorial(reply_to, 50))
}

type Factorial {
  Factorial(reply_to: Subject(Int), n: Int)
}

fn factorial_server() -> Subject(Factorial) {
  process.new_subject()
}

fn factorial(n: Int) -> Int {
  case n {
    0 -> 1
    n if n > 0 -> factorial(n - 1)
    _ -> panic as "cannot calculate negative factorial"
  }
}
