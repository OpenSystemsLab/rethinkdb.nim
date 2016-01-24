import unittest, json
import ../rethinkdb

let r = newRethinkClient()
r.connect()
r.repl()

suite "math and logic tests":
  test "add":
    let output = 2
    var ret: JsonNode
    ret = (r.expr(1) + 1).run()
    check(ret.getNum() == output)
    ret = (1 + r.expr(1)).run()
    check(ret.getNum() == output)
    ret = r.expr(1).add(1).run()
    check(ret.getNum() == output)

r.close()
