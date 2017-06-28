version       = "0.2.0"
author        = "Huy Doan"
description   = "RethinkDB driver for Nim"
license       = "MIT"

skipDirs      = @["tests", "bench"]

requires "nim >= 0.17.0", "struct >= 0.1.1"



task test, "Runs the test suite":
  exec "nim c -r --hints:off --threads:on tests/test_bracket.nim"
  exec "nim c -r --hints:off --threads:on tests/test_db.nim"
  exec "nim c -r --hints:off --threads:on tests/test_geo.nim"
  exec "nim c -r --hints:off --threads:on tests/test_lambdas.nim"
  exec "nim c -r --hints:off --threads:on tests/test_math_logic.nim"
  exec "nim c -r --hints:off --threads:on tests/test_ordering.nim"
  exec "nim c -r --hints:off --threads:on tests/test_threaded.nim"
 