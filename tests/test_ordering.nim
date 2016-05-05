import unittest, json
import ../rethinkdb

let r = newRethinkClient()
r.connect()
r.repl()



discard r.table("posts").orderBy(index=r.desc("date")).run()
discard r.table("posts").orderBy(r.desc("date")).run()
