import gleam/erlang/process.{type Subject}
import gleeunit
import gleeunit/should
import universal_server

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn universal_server_test() {
  let universal_subject = should.be_ok(universal_server.start(True))

  let concrete_subject =
    universal_subject
    |> universal_server.become(factorial_server)
    |> should.be_ok()

  should.equal(
    process.subject_owner(universal_subject),
    process.subject_owner(concrete_subject),
  )

  concrete_subject
  |> compute(50)
  |> should.be_ok()
  |> should.equal(
    30_414_093_201_713_378_043_612_608_166_064_768_844_377_641_568_960_512_000_000_000_000,
  )

  let reply_to = process.new_subject()

  process.start(
    fn() { process.send(reply_to, compute(concrete_subject, 3)) },
    True,
  )

  reply_to
  |> process.receive(5000)
  |> should.be_ok()
  |> should.be_ok()
  |> should.equal(6)
}

type Factorial {
  Factorial(reply_to: Subject(Int), n: Int)
}

fn compute(subject: Subject(Factorial), n: Int) -> Result(Int, Nil) {
  let reply_to = process.new_subject()
  process.send(subject, Factorial(reply_to, n))
  process.receive(reply_to, 5000)
}

fn factorial_server(subject: Subject(Factorial)) {
  let Factorial(reply_to, n) =
    process.new_selector()
    |> process.selecting(subject, fn(m) { m })
    |> process.select_forever()

  process.send(reply_to, factorial(n))

  factorial_server(subject)
}

fn factorial(n: Int) -> Int {
  case n {
    0 -> 1
    n if n > 0 -> n * factorial(n - 1)
    _ -> panic as "cannot calculate negative factorial"
  }
}
