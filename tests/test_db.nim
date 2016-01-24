import unittest, json, math
import ../rethinkdb

randomize()

let db = "test_db_" & $random(9999)
var ret: JsonNode
let r = newRethinkClient()
r.connect()
r.repl()


suite "database manipulation tests":
  test "create database":
    ret = r.dbCreate(db).run()
    check(ret["dbs_created"].num == 1)

  test "list database":
    ret = r.dbList().run()
    var found = false
    for x in ret.items():
      if x.str == db:
        found = true
        break
    check(found)

  test "drop database":
    ret = r.dbDrop(db).run()
    check(ret["dbs_dropped"].num == 1)


r.close()
