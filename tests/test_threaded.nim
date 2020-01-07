import threadpool
import ../rethinkdb

setMaxPoolSize(64)

var r: RethinkClient

proc insert(r: RethinkClient, c: int) =
  r.table("test").insert(&*{"c": c}).run(r, noreply=true, durability="soft")

r = R.connect().use("test").repl()
for x in 0..1_000:
  spawn insert(r, x)
r.close()
