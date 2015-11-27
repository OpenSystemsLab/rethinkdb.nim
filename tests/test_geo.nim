import einheit
import asyncdispatch
import json
import math

import ../rethinkdb

testSuite GeospatialTests:
  var
    r: RethinkClient
    db: string

  method setup()=
    self.r = newRethinkClient()
    waitFor self.r.connect()
    self.r.repl()

  method tearDown()=
    self.r.close()

  method testPoint()=
    var point1 = self.r.point(-122.423246,37.779388)
    var point2 = self.r.point(-117.220406,32.719464)

    var distance = waitFor self.r.distance(point1, point2, unit="km").run()
    assert distance.fnum == 734.125249602186

    distance = waitFor self.r.distance(point1, point2).run()
    assert distance.fnum == 734125.249602186


when isMainModule:
  runTests()
