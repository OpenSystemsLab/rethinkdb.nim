import unittest, json, random
import ../rethinkdb

let r = R.connect().repl()
randomize()
let db = "test_geo_" & $rand(9999)
let table = "nodes"

discard r.dbCreate(db).run()
r.use(db)
discard r.tableCreate(table).run()
discard r.table(table).indexCreate("loc", geo = true).run()
discard r.table(table).indexWait("loc").run()

suite "geospatial tests":
  test "point":
    var point1 = r.point(-122.423246,37.779388)
    var point2 = r.point(-117.220406,32.719464)
    #var c1 = self.r.circle([-122.423246, 37.779388], 1000).run()

    var distance = r.distance(point1, point2, unit="km").run()
    check(distance.fnum.int == 734)

    distance = r.distance(point1, point2).run()
    check(distance.fnum.int == 734125)

    discard r.table("nodes").insert([
      &*{"id": 1, "loc": point1},
      &*{"id": 2, "loc": point2}]).run()

  test "json":
    var p1 = r.geojson(r"{""type"": ""Point"", ""coordinates"":[-122.423246, 37.779388]}").run()
    var p2 = r.table(table).get(1)["loc"].to_geojson.run()

  test "intersecting":
    var circle1 = r.circle([-117.220406,32.719464], 10, unit="mi")
    discard r.table(table).getIntersecting(circle1, index="loc").run()

  test "line":
    var line = r.line([-122.423246,37.779388], [-121.886420,37.329898]).run()

discard r.dbDrop(db).run()
r.close()
