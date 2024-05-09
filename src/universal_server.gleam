import gleam/erlang/process.{type Subject}

pub fn start(linked: Bool) -> Result(Subject(fn() -> a), Nil) {
  let reply_to = process.new_subject()

  process.start(
    fn() {
      let universal_subject = process.new_subject()
      process.send(reply_to, universal_subject)

      {
        process.new_selector()
        |> process.selecting(universal_subject, fn(m) { m })
        |> process.select_forever()
      }()
    },
    linked,
  )

  process.receive(reply_to, 5000)
}

pub fn become(
  universal_subject: Subject(fn() -> a),
  fun: fn(Subject(b)) -> a,
) -> Result(Subject(b), Nil) {
  let reply_to = process.new_subject()

  process.send(universal_subject, fn() {
    let specific_subject = process.new_subject()
    process.send(reply_to, specific_subject)
    fun(specific_subject)
  })

  process.receive(reply_to, 1000)
}
