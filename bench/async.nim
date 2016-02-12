import asyncdispatch
import ../../nimbench/nimbench
import ../rethinkdb

bench(async, m):
  var r = newRethinkClient()
  waitfor r.connect()
  r.repl()
  for _ in 1..m:
    let future = r.table("tv_shows").run()
    future.callback =
        proc () =
          discard future.read()
  r.close()
runBenchmarks()
