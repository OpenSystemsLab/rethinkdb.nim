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
    check(ret.num == output)
    ret = (1 + r.expr(1)).run()
    check(ret.num == output)
    ret = r.expr(1).add(1).run()
    check(ret.num == output)

    ret = (r.expr(1.75) + 8.5).run()
    check(ret.fnum == 10.25)

  test "add w/ strings":
    var ret = (r.expr("") + "").run()
    check(ret.str == "")

    ret = (r.expr("abc") + "def").run()
    check(ret.str == "abcdef")

  test "add w/ arrays":
    var ret = (r.expr([1,2]) + [3] + [4,5] + [6,7,8]).run()
    check(ret == %*[1,2,3,4,5,6,7,8])

  test "type errors":
    expect(RqlRuntimeError):
      discard (r.expr(1) + "a").run()

    expect(RqlRuntimeError):
      discard (r.expr("a") + 1).run()

r.close()
