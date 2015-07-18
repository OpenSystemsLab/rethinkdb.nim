import einheit
import asyncdispatch
import json
import math
import future

import ../rethinkdb

testSuite LambdasTests:
  var
    r: RethinkClient
    db: string
    table: string

  method setup()=
    self.r = newRethinkClient()
    self.r.connect().repl()
    randomize()
    self.db = "test_lambda_" & $random(9999)
    self.table = "SuperHeroes"

    discard waitFor self.r.dbCreate(self.db).run()
    self.r.use(self.db)
    discard waitFor self.r.tableCreate(self.table).run()
    discard waitFor self.r.table(self.table).insert(
      [&*{"name": "Iron Man", "age": 30},
      &*{"name": "Spider Man", "age": 23},
      &*{"name": "Batman", "age": 25}]
    ).run()


  method tearDown()=
    discard waitFor self.r.dbDrop(self.db).run()
    self.r.close()

  method testMap()=
    let ages = waitFor self.r.table(self.table).map((x: RqlQuery) => x["age"]).run()
    self.check(ages.elems.len == 3)
    self.check(ages[0].num.int in @[30, 23, 25])
    self.check(ages[1].num.int in @[30, 23, 25])
    self.check(ages[2].num.int in @[30, 23, 25])

  method testMapWithExpression()=
    let ages = waitFor self.r.table(self.table).map((x: RqlQuery) => x["age"] + 20).run()
    self.check(ages.elems.len == 3)
    self.check(ages[0].num.int in @[50, 43, 45])
    self.check(ages[1].num.int in @[50, 43, 45])
    self.check(ages[2].num.int in @[50, 43, 45])

when isMainModule:
  runTests()
