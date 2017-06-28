import json

proc circle*(r: RethinkClient, loc: auto, radius: int, numVertices = 32, geoSystem = "", unit = "", fill = true): RqlQuery =
  NEW_QUERY(CIRCLE, loc, radius)

  if numVertices != 32:
    result.setOption("num_vertices", numVertices)

  if geoSystem != "" and geoSystem != "WGS84":
    result.setOption("geo_system", geoSystem)

  if unit != "":
    result.setOption("unit", unit)

  if not fill:
    result.setOption("fill", false)

proc distance*[T: RethinkClient|RqlQuery](r: T, p1, p2: auto, geoSystem = "", unit = ""): RqlQuery =
  NEW_QUERY(DISTANCE, p1, p2)

  if geoSystem != "" and geoSystem != "WGS84":
    result.setOption("geo_system", geoSystem)

  if unit != "":
    result.setOption("unit", unit)

proc fill*[T](r: T): RqlQuery =
  NEW_QUERY(FILL)

proc geojson*[T](r: T, json: JsonNode): RqlQuery =
  NEW_QUERY(GEOJSON, json)

proc geojson*[T](r: T, json: string): RqlQuery =
  r.geojson(parseJson(json))

proc toGeojson*[T](r: T): RqlQuery =
  #TODO
  NEW_QUERY(TO_GEOJSON, r)

proc getInterSecting*[T: array[2, float]|RqlQuery](r: RqlQuery, geometry: T, index = ""): RqlQuery =
  NEW_QUERY(GET_INTERSECTING, r, geometry)
  if index != "":
    result.setOption("index", index)

proc getNearest*[T: array[2, float]|RqlQuery](r: RqlQuery, point: T, index = "", maxResults = 100, maxDist = 100_000, unit= "", geoSystem=""): RqlQuery =
  NEW_QUERY(GET_NEAREST, r, point)
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
  NEW_QUERY(INCLUDES, geometry)

proc intersecs*[T](r: T, geometry: RqlQuery): RqlQuery =
  NEW_QUERY(INTERSECTS, geometry)

proc line*[T: array[2, float]|RqlQuery](r: RethinkClient, geometries: varargs[T]): RqlQuery =
  NEW_QUERY(LINE)
  for x in geometries:
    result.addArg(x)

proc point*[T](r: T, lon, lat: float): RqlQuery =
  NEW_QUERY(POINT, lon, lat)

proc polygon*[T, U: array[2, float]|RqlQuery](r: T, geometries: varargs[U]): RqlQuery =
  NEW_QUERY(POLYGON)
  for x in geometries:
    result.addArg(x)

proc polygonSub*[T, U: array[2, float]|RqlQuery](r: T, polygon2: U): RqlQuery =
  NEW_QUERY(POLYGON_SUB, polygon2)
