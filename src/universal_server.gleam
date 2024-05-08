import gleam/erlang/process.{type Subject}

pub opaque type Become(a) {
  Become(reply_to: Subject(Subject(a)), fun: fn(Subject(a)) -> Nil)
}

pub fn start(linked: Bool) -> Result(Subject(Become(a)), Nil) {
  let start_reply_to = process.new_subject()

  process.start(
    fn() {
      let universal_subject = process.new_subject()
      process.send(start_reply_to, universal_subject)

      let Become(become_reply_to, fun) =
        process.new_selector()
        |> process.selecting(universal_subject, fn(m) { m })
        |> process.select_forever()

      let concrete_subject = process.new_subject()

      process.send(become_reply_to, concrete_subject)

      fun(concrete_subject)
    },
    linked,
  )

  process.receive(start_reply_to, 5000)
}

pub fn become(
  universal_subject: Subject(Become(a)),
  fun: fn(Subject(a)) -> Nil,
) -> Result(Subject(a), Nil) {
  let reply_to = process.new_subject()

  process.send(universal_subject, Become(reply_to, fun))

  process.receive(reply_to, 5000)
}
