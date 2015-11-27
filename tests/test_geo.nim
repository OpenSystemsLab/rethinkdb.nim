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

  method estPoint()=
    var point1 = self.r.point(-122.423246,37.779388)
    var point2 = self.r.point(-117.220406,32.719464)
    #var c1 = self.r.circle([-122.423246, 37.779388], 1000).run()

    #var distance = waitFor self.r.distance(point1, point2, unit="km").run()
    #assert distance.fnum.int == 734

    #distance = waitFor self.r.distance(point1, point2).run()
    #assert distance.fnum.int == 734125

    #discard waitFor self.r.table("nodes").insert([
    #  &*{"id": 1, "loc": point1},
    #  &*{"id": 2, "loc": point2}]).run()

  method testJson()=
    var p1 = waitFor self.r.geojson(r"{""type"": ""Point"", ""coordinates"":[-122.423246, 37.779388]}").run()
    var p2 = waitFor self.r.table("nodes").get(1)["loc"].to_geojson.run()

  method testIntersecting()=
    var  circle1 = self.r.circle([-117.220406,32.719464], 10, unit="mi")
    discard waitFor self.r.table("nodes").getIntersecting(circle1, index="loc").run()

  method testLine()=
    var line = waitFor self.r.line([-122.423246,37.779388], [-121.886420,37.329898]).run()


when isMainModule:
  runTests()
