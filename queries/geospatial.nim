import json

proc circle*[T](r: T, loc: array[0..1, float], radius: int, numVertices = 32, geoSystem = "", unit = "", fill = true): RqlQuery =
  newQueryAst(CIRCLE, loc, radius)

  if numVertices != 32:
    result.setOption("num_vertices", numVertices)

  if geoSystem != "" and geoSystem != "WGS84":
    result.setOption("geo_system", geoSystem)

  if unit != "":
    result.setOption("unit", unit)

  if not fill:
    result.setOption("fill", false)

proc distance*[T](r: T, p1, p2: RqlQuery, geoSystem = "", unit = ""): RqlQuery =
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

proc getInterSecting*(r: RqlTable, geometry: RqlQuery, index = ""): RqlQuery =
  newQueryAst(GET_INTERSECTING, r, geometry)
  if index != "":
    result.setOption("index", index)

proc getNearest*(r: RqlTable, point: RqlQuery, index = "", maxResults = 100, maxDist = 100_000, unit= "", geoSystem=""): RqlQuery =
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

proc line*[T](r: T, geometries: varargs[RqlQuery]): RqlQuery =
  newQueryAst(LINE)
  for x in geometries:
    result.addArg(x)

proc line*[T](r: T, geometries: varargs[array[0..1, float]]): RqlQuery =
  newQueryAst(LINE)
  for x in geometries:
    result.addArg(x)

proc point*[T](r: T, lon, lat: float): RqlQuery =
  newQueryAst(POINT, lon, lat)

proc polygon*[T](r: T, geometries: varargs[RqlQuery]): RqlQuery =
  newQueryAst(POLYGON)
  for x in geometries:
    result.addArg(x)

proc polygon*[T](r: T, geometries: varargs[array[0..1, float]]): RqlQuery =
  newQueryAst(POLYGON)
  for x in geometries:
    result.addArg(x)

proc polygonSub*[T](r: T, polygon2: RqlQuery): RqlQuery =
  newQueryAst(POLYGON_SUB, polygon2)
