import threadpool
import ../rethinkdb

setMaxPoolSize(64)

proc insert(c: int) =
  {.gcsafe.}:
    var r = newRethinkClient()
    r.connect()
    r.use("test")
    r.table("test").insert(&*{"c": c}).run(r, noreply=true, durability="soft")
    r.close()

#for x in 0..1_000:
#  spawn insert(x)
