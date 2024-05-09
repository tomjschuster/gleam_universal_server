import gleam/erlang/process.{type Subject}

pub fn start(linked: Bool) -> Result(Subject(fn() -> a), Nil) {
  let reply_to = process.new_subject()

  process.start(
    fn() {
      let subject = process.new_subject()
      process.send(reply_to, subject)

      {
        process.new_selector()
        |> process.selecting(subject, fn(m) { m })
        |> process.select_forever()
      }()
    },
    linked,
  )

  process.receive(reply_to, 5000)
}

pub fn become(
  subject: Subject(fn() -> a),
  fun: fn(Subject(b)) -> a,
) -> Result(Subject(b), Nil) {
  let reply_to = process.new_subject()

  process.send(subject, fn() {
    let concrete_subject = process.new_subject()
    process.send(reply_to, concrete_subject)
    fun(concrete_subject)
  })

  process.receive(reply_to, 1000)
}
