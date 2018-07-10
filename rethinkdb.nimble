version       = "0.2.3.2"
author        = "Huy Doan"
description   = "RethinkDB driver for Nim"
license       = "MIT"

skipDirs      = @["tests", "bench"]

requires "nim >= 0.18.0", "struct >= 0.1.1", "scram >= 0.1.1"



task test, "Runs the test suite":
  exec "nim c -r tests/test_bracket.nim"
  exec "nim c -r tests/test_db.nim"
  exec "nim c -r tests/test_geo.nim"
  exec "nim c -r tests/test_lambdas.nim"
  exec "nim c -r tests/test_math_logic.nim"
  exec "nim c -r tests/test_ordering.nim"
  exec "nim c -r tests/test_threaded.nim"
 
