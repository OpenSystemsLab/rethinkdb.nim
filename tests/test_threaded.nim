import json, threadpool
import ../rethinkdb

#var r {.threadvar.}: RethinkClient

#r = newRethinkClient()
#r.connect()

#setMaxPoolSize(64)
proc insert(c: int) {.thread.} =
  var r = newRethinkClient()
  r.connect()
  discard r.db("test").table("test").insert(&*{"c": c}).run(r, noreply=true, durability="soft")
  r.close()


for x in 0..100_000:
  spawn insert(x)

sync()
