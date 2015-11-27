proc point*[T](r: T, lon, lat: float): RqlQuery =
  newQueryAst(POINT, lon, lat)


proc distance*[T](r: T, p1, p2: RqlQuery, geoSystem = "", unit = "m"): RqlQuery =
  newQueryAst(DISTANCE, p1, p2)

  if geoSystem != "" and geoSystem != "WGS84":
    result.setOption("geo_system", geoSystem)

  if unit != "":
    result.setOption("unit", unit)
