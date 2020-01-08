
import unittest, json, random
import ../rethinkdb

randomize()

let db = "test_hook_" & $rand(9999)
let table = "SuperHeroes"

suite "changes tests":
  let r = R.connect().repl()
  var res: JsonNode

  discard r.dbCreate(db).run()
  r.use(db)
  discard r.tableCreate(table).run()

  test "remove write hook":
    proc cb(data: JsonNode) =
      echo "changes ", data
    #echo r.table(table).changes().run(callback=cb)

  discard r.dbDrop(db).run()
  r.close()
