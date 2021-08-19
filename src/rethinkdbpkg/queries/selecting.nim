#--------------------
# Selecting data
#--------------------

proc db*(r: RethinkClient, db: string): RqlQuery =
  ## Reference a database.
  NEW_QUERY(DB)

proc table*[T: RethinkClient|RqlQuery](r: T, t: string): RqlQuery =
  ## Select all documents in a table
  when r is RethinkClient:
    NEW_QUERY(TABLE_R, t)
  else:
    NEW_QUERY(TABLE_R, r, t)

proc get*(r: RqlQuery, t: int): RqlQuery =
  ## Get a document by primary key
  NEW_QUERY(GET, r, t)

proc get*(r: RqlQuery, t: string): RqlQuery =
  ## Get a document by primary key
  NEW_QUERY(GET, r, t)

proc getAll*[T: int|string](r: RqlQuery, args: openArray[T], index = ""): RqlQuery =
  ## Get all documents where the given value matches the value of the requested index
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##  # with primary index
  ##  r.table("posts").getAll([1, 1]).run()
  ##  # with secondary index
  ##  r.table("posts").getAll(["nim", "lang"], "tags").run()
  NEW_QUERY(r)
  for x in args:
    result.addArg(@x)

  if index != "":
    result.setOption("index", index)

proc between*(r: RqlQuery, lowerKey, upperKey: MutableDatum, index = "id", leftBound = "closed", rightBound = "open"): RqlQuery =
  ## Get all documents between two keys
  NEW_QUERY(BETWEEN, r, lowerKey, upperKey)
  
  if index != "id":
    result.setOption("index", index)
  if leftBound != "closed":
    result.setOption("left_bound", leftBound)
  if rightBound != "open":
    result.setOption("right_bound", rightBound)

proc filter*[T: MutableDatum|RqlQuery](r: RqlQuery, data: T, default = false): RqlQuery =
  ## Get all the documents for which the given predicate is true
  NEW_QUERY(FILTER, r)

  result.addArg(r.makeFunc(data))
  if default:
    result.setOption("default", true)

proc filter*[T](r: RqlQuery, f: proc(x: RqlQuery): T, default = false): RqlQuery =
  NEW_QUERY(FILTER, r)
  result.addArg(funcWrap(f))
  if default:
    result.setOption("default", true)
