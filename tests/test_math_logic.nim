import unittest, json
import ../rethinkdb

suite "math and logic tests":
  let r = R.connect().repl()
  var ret: JsonNode

  test "add":
    let output = 2
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

  test "bit wises":
    ret = r.expr(5).bitAnd(3).run()
    check(ret.getInt == 1)

    ret = r.expr(7).bitNot().run()
    check(ret.getInt == -8)

    ret = r.expr(5).bitOr(3).run()
    check(ret.getInt == 7)

    ret = r.expr(5).bitShl(4).run()
    check(ret.getInt == 80)

    ret = r.expr(32).bitShr(3).run()
    check(ret.getInt == 4)

    ret = r.expr(6).bitXor(4).run()
    check(ret.getInt == 2)

  r.close()
