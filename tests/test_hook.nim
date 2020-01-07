
import unittest, json, random
import ../rethinkdb

randomize()

let db = "test_hook_" & $rand(9999)
let table = "SuperHeroes"

suite "lambda tests":
  let r = R.connect().repl()
  var res: JsonNode

  discard r.dbCreate(db).run()
  r.use(db)
  discard r.tableCreate(table).run()

  test "remove write hook":
    discard r.table(table).setWriteHook().run()

  test "get null write hook":
    res = r.table(table).getWriteHook().run()
    check(res.kind == JNull)

  test "set write hook":
    res = r.table(table).setWriteHook((ctx, oldValue, newValue: RqlQuery) => newValue.merge({"modified_at": ctx["timestamp"]})).run()
    check(res["created"].getInt == 1)

  test "get non-null write hook":
    res = r.table(table).getWriteHook().run()
    check(res.hasKey("function"))
    check(res["query"].getStr == r"setWriteHook(function(var1, var2, var3) { return var3.merge({""modified_at"": var1(""timestamp"")}); })")

  test "insert data into table":
    res = r.table(table).insert(&*{"name": "Iron Man", "age": 30, "modified_at": 0}).run()
    check(res["inserted"].getInt == 1)
    res = r.table(table).get(res["generated_keys"][0].getStr).run()
    check(res["modified_at"].kind == JObject)
    check(res["modified_at"]["$reql_type$"].getStr == "TIME")

  discard r.dbDrop(db).run()
  r.close()
