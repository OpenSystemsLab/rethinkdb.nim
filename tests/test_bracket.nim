import unittest, json, random
import ../rethinkdb

randomize()

suite "bracket tests":
  var r: RethinkClient
  let db = "test_bracket_" & $rand(9999)
  let tableName = "SuperHeroes"
  r = newRethinkClient()
  r.connect()
  r.repl()

  test "create database":
    discard r.dbCreate(db).run()

  test "create table":
    r.use(db)
    discard r.tableCreate(tableName).run()

  test "insert sample data":
    discard r.table(tableName).insert(&*[
      {"id": 1, "name": "Iron Man", "age": 30},
      {"id": 2, "name": "Spider Man", "age": 23},
      {"id": 3, "name": "Batman", "age": 25}
    ]).run()

  test "get an element from sequence":
    let ret = r.expr([10, 20, 30, 40, 50])[3].run()
    check(ret.getInt() == 40)

  test "get single field from document":
    let ret = r.table(tableName).get(2)["age"].run()
    check(ret.getInt() == 23)

  discard r.dbDrop(db).run()
  r.close()

