import unittest, json, random
import ../rethinkdb

randomize()
let db = "test_bracket_" & $random(9999)
let tableName = "SuperHeroes"
let r = newRethinkClient()
r.connect()
r.repl()

discard r.dbCreate(db).run()
r.use(db)

discard r.tableCreate(tableName).run()
discard r.table(tableName).insert([
  &*{"id": 1, "name": "Iron Man", "age": 30},
  &*{"id": 2, "name": "Spider Man", "age": 23},
  &*{"id": 3, "name": "Batman", "age": 25}
]).run()


suite "bracket tests":
  test "get an element from sequence":
    let ret = r.expr([10, 20, 30, 40, 50])[3].run()
    check(ret.getNum() == 40)

  test "get single field from document":
    let ret = r.table(tableName).get(2)["age"].run()
    check(ret.getNum() == 23)


discard r.dbDrop(db).run()
r.close()
