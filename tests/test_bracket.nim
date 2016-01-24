import unittest, asyncdispatch, json, math


import ../rethinkdb

suite "bracket tests":
  setup:
    randomize()
    let db = "test_bracket_" & $random(9999)
    let table = "SuperHeroes"
    let r = newRethinkClient()
    waitFor r.connect()
    r.repl()

    discard waitFor r.dbCreate(db).run()
    r.use(db)
    discard waitFor r.tableCreate(table).run()
    discard waitFor r.table(table).insert(
      [&*{"id": 1, "name": "Iron Man", "age": 30},
      &*{"id": 2, "name": "Spider Man", "age": 23},
      &*{"id": 3, "name": "Batman", "age": 25}]
    ).run()

  teardown:
    discard waitFor r.dbDrop(db).run()
    r.close()

  test "get an element from sequence":
    let ret = waitFor r.expr([10, 20, 30, 40, 50])[3].run()
    check(ret.getNum() == 40)

  test "get single field from document":
    let ret = waitFor r.table(table).get(2)["age"].run()
    check(ret.getNum() == 23)
