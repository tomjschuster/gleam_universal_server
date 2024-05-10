import gleam/erlang/process.{type Subject}
import gleam/result
import gleeunit
import gleeunit/should
import universal_server

pub fn main() {
  gleeunit.main()
}

pub fn universal_server_test_() {
  [become_, same_process_, sub_process_, become_only_once_, become_twice_]
}

fn become_() {
  let subject =
    universal_server.start(True)
    |> should.be_ok()
    |> universal_server.become(factorial_server)
    |> should.be_ok()

  subject
  |> compute(5)
  |> should.be_ok()
  |> should.equal(120)

  subject
  |> compute(50)
  |> should.be_ok()
  |> should.equal(
    30_414_093_201_713_378_043_612_608_166_064_768_844_377_641_568_960_512_000_000_000_000,
  )
}

fn same_process_() {
  let universal_subject = should.be_ok(universal_server.start(True))

  universal_subject
  |> universal_server.become(factorial_server)
  |> should.be_ok()
  |> process.subject_owner()
  |> should.equal(process.subject_owner(universal_subject))
}

fn sub_process_() {
  let subject =
    universal_server.start(True)
    |> should.be_ok()
    |> universal_server.become(summation_server)
    |> should.be_ok()

  let reply_to = process.new_subject()

  process.start(fn() { process.send(reply_to, compute(subject, 50)) }, True)

  reply_to
  |> process.receive(1000)
  |> result.flatten()
  |> should.be_ok()
  |> should.equal(1275)
}

fn become_only_once_() {
  let universal_subject =
    universal_server.start(True)
    |> should.be_ok()

  universal_subject
  |> universal_server.become(factorial_server)
  |> should.be_ok()

  universal_subject
  |> universal_server.become(summation_server)
  |> should.be_error()

  Nil
}

fn become_twice_() {
  let universal_subject =
    universal_server.start(True)
    |> should.be_ok()

  universal_subject
  |> universal_server.become(resetable_factorial_server(_, universal_subject))
  |> should.be_ok()
  |> compute(10)
  |> should.be_ok()
  |> should.equal(3_628_800)

  universal_subject
  |> universal_server.become(summation_server)
  |> should.be_ok()
  |> compute(50)
  |> should.be_ok()
  |> should.equal(1275)
}

fn factorial_server(subject: Subject(#(Subject(Int), Int))) {
  let #(reply_to, n) =
    process.new_selector()
    |> process.selecting(subject, fn(m) { m })
    |> process.select_forever()

  process.send(reply_to, factorial(n))

  factorial_server(subject)
}

type ResetableFactorialMessage(a) {
  Factorial(reply_to: Subject(Int), n: Int)
  UniversalServer(fn() -> a)
}

fn resetable_factorial_server(
  subject: Subject(#(Subject(Int), Int)),
  universal_subject: Subject(fn() -> a),
) {
  let message =
    process.new_selector()
    |> process.selecting(subject, fn(tuple) { Factorial(tuple.0, tuple.1) })
    |> process.selecting(universal_subject, fn(fun) { UniversalServer(fun) })
    |> process.select_forever()

  case message {
    UniversalServer(fun) -> fun()
    Factorial(reply_to, n) -> {
      process.send(reply_to, factorial(n))
      resetable_factorial_server(subject, universal_subject)
    }
  }
}

fn summation_server(subject: Subject(#(Subject(Int), Int))) {
  let #(reply_to, n) =
    process.new_selector()
    |> process.selecting(subject, fn(m) { m })
    |> process.select_forever()

  process.send(reply_to, summation(n))

  summation_server(subject)
}

fn factorial(n: Int) -> Int {
  case n {
    0 -> 1
    n if n > 0 -> n * factorial(n - 1)
    _ -> panic as "cannot calculate negative factorial"
  }
}

fn summation(n: Int) -> Int {
  case n {
    0 -> 0
    n if n > 0 -> n + summation(n - 1)
    _ -> panic as "cannot calculate negative summation"
  }
}

fn compute(subject: Subject(#(Subject(Int), Int)), n: Int) -> Result(Int, Nil) {
  let reply_to = process.new_subject()
  process.send(subject, #(reply_to, n))
  process.receive(reply_to, 1000)
}
