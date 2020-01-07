import unittest, json, random
import ../rethinkdb

let r = R.connect().repl()

randomize()
let db = "test_lambda_" & $rand(9999)
let table = "SuperHeroes"

r.dbCreate(db).run()
r.use(db)
r.tableCreate(table).run()
r.table(table).insert([
  &*{"name": "Iron Man", "age": 30},
  &*{"name": "Spider Man", "age": 23},
  &*{"name": "Batman", "age": 25
}]).run()

var res: JsonNode

suite "ordering tests":
  test "create index on age":
    r.table(table).indexCreate("age").run()
    r.table(table).indexWait("age").run()
  test "order by field":
    res = r.table(table).orderBy(r.desc("name")).pluck("name").run()
    check(res[0] == %*{"name": "Spider Man"})
    check(res[2] == %*{"name": "Batman"})
  test "order by index":
    res = r.table(table).orderByIndex(r.asc("age")).pluck("age").run()
    check(res[0] == %*{"age": 23})
    check(res[2] == %*{"age": 30})

r.dbDrop(db).run()
r.close()
