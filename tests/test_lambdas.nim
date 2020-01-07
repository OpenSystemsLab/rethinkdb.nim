import unittest, json, random
import ../rethinkdb

let r = R.connect().repl()

randomize()
let db = "test_lambda_" & $rand(9999)
let table = "SuperHeroes"

discard r.dbCreate(db).run()
r.use(db)
discard r.tableCreate(table).run()
discard r.table(table).insert([
  &*{"name": "Iron Man", "age": 30},
  &*{"name": "Spider Man", "age": 23},
  &*{"name": "Batman", "age": 25
}]).run()

var res: JsonNode

suite "lambda tests":
  test "map":
    res = r.expr(&*[1, 2, 3, 4, 5]).map((val: RqlQuery) => val * val).run()
    check(res == %*[1, 4, 9, 16, 25])

  test "map field":
    res = r.table(table).map((x: RqlQuery) => x["age"]).run()
    check(res.elems.len == 3)
    check(res[0].num.int in @[30, 23, 25])
    check(res[1].num.int in @[30, 23, 25])
    check(res[2].num.int in @[30, 23, 25])

  test "map with expression":
    checkpoint("lambda with add expression")
    res = r.table(table).map((x: RqlQuery) => x["age"] + 20).run()
    check(res.elems.len == 3)
    check(res[0].num.int in @[50, 43, 45])
    check(res[1].num.int in @[50, 43, 45])
    check(res[2].num.int in @[50, 43, 45])

    checkpoint("lambda with comparision expression")
    res = r.table(table).map((x: RqlQuery) => x["age"] >= 30).run()
    check(res.elems.len == 3)

discard r.dbDrop(db).run()
r.close()
