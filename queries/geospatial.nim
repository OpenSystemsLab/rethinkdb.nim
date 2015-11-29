import json

proc circle*[T, U: array[2, float]|RqlQuery](r: T, loc: U, radius: int, numVertices = 32, geoSystem = "", unit = "", fill = true): RqlQuery =
  newQueryAst(CIRCLE, loc, radius)

  if numVertices != 32:
    result.setOption("num_vertices", numVertices)

  if geoSystem != "" and geoSystem != "WGS84":
    result.setOption("geo_system", geoSystem)

  if unit != "":
    result.setOption("unit", unit)

  if not fill:
    result.setOption("fill", false)

proc distance*[T, U: array[2, float]|RqlQuery](r: T, p1, p2: U, geoSystem = "", unit = ""): RqlQuery =
  newQueryAst(DISTANCE, p1, p2)

  if geoSystem != "" and geoSystem != "WGS84":
    result.setOption("geo_system", geoSystem)

  if unit != "":
    result.setOption("unit", unit)

proc distance*[T](r: T, p1, p2: array[0..1, float], geoSystem = "", unit = ""): RqlQuery =
  newQueryAst(DISTANCE, p1, p2)

  if geoSystem != "" and geoSystem != "WGS84":
    result.setOption("geo_system", geoSystem)

  if unit != "":
    result.setOption("unit", unit)

proc fill*[T](r: T): RqlQuery =
  newQueryAst(FILL)

proc geojson*[T](r: T, json: JsonNode): RqlQuery =
  newQueryAst(GEOJSON, json)

proc geojson*[T](r: T, json: string): RqlQuery =
  r.geojson(parseJson(json))

proc toGeojson*[T](r: T): RqlQuery =
  #TODO
  newQueryAst(TO_GEOJSON, r)

proc getInterSecting*[T: array[2, float]|RqlQuery](r: RqlTable, geometry: T, index = ""): RqlQuery =
  newQueryAst(GET_INTERSECTING, r, geometry)
  if index != "":
    result.setOption("index", index)

proc getNearest*[T: array[2, float]|RqlQuery](r: RqlTable, point: T, index = "", maxResults = 100, maxDist = 100_000, unit= "", geoSystem=""): RqlQuery =
  newQueryAst(GET_NEAREST, r, point)
  if index != "":
    result.setOption("index", index)

  if maxResults != 100:
    result.setOption("max_results", maxResults)

  if maxDist != 100_000:
    result.setOption("max_dist", maxDist)

  if geoSystem != "" and geoSystem != "WGS84":
    result.setOption("geo_system", geoSystem)

  if unit != "":
    result.setOption("unit", unit)

proc includes*[T](r: T, geometry: RqlQuery): RqlQuery =
  newQueryAst(INCLUDES, geometry)

proc intersecs*[T](r: T, geometry: RqlQuery): RqlQuery =
  newQueryAst(INTERSECTS, geometry)

proc line*[T, U: array[2, float]|RqlQuery](r: T, geometries: varargs[U]): RqlQuery =
  newQueryAst(LINE)
  for x in geometries:
    result.addArg(x)

proc point*[T](r: T, lon, lat: float): RqlQuery =
  newQueryAst(POINT, lon, lat)

proc polygon*[T, U: array[2, float]|RqlQuery](r: T, geometries: varargs[U]): RqlQuery =
  newQueryAst(POLYGON)
  for x in geometries:
    result.addArg(x)

proc polygonSub*[T, U: array[2, float]|RqlQuery](r: T, polygon2: U): RqlQuery =
  newQueryAst(POLYGON_SUB, polygon2)
