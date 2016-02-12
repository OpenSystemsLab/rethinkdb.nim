import asyncdispatch
import ../../nimbench/nimbench
import ../rethinkdb

bench(sync, m):
  var r = newRethinkclient()
  r.connect()
  r.repl()
  for _ in 1..m:
    discard r.table("tv_shows").run()
  r.close()

runBenchmarks()
