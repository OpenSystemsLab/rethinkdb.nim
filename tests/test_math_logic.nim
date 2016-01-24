import unittest, asyncdispatch, json, math

randomize()

import ../rethinkdb

suite "math and logic tests":
  setup:
    let r = newRethinkClient()
    waitFor r.connect()
    r.repl()
  teardown:
    r.close()

  test "add":
    let output = 2
    var ret: JsonNode
    ret = waitFor ((r.expr(1) + 1).run())
    check(ret.getNum() == output)
    ret = waitFor ((1 + r.expr(1)).run())
    check(ret.getNum() == output)
    ret = waitFor r.expr(1).add(1).run()
    check(ret.getNum() == output)
