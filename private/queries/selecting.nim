#--------------------
# Selecting data
#--------------------

proc db*(r: RethinkClient, db: string): RqlQuery =
  ## Reference a database.
  newQueryAst(DB)

proc table*(r: RethinkClient, t: string): RqlQuery =
  ## Select all documents in a table
  when r is RethinkClient:
    newQueryAst(TABLE_R, t)
  else:
    newQueryAst(TABLE_R, r, t)

proc get*[T: int|string](r: RqlQuery, t: T): RqlQuery =
  ## Get a document by primary key
  newQueryAst(GET, r, t)

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
  newQueryAst(GET_ALL, r)
  for x in args:
    result.addArg(@x)

  if index != "":
    result.setOption("index", index)

proc between*(r: RqlQuery, lowerKey, upperKey: MutableDatum, index = "id", leftBound = "closed", rightBound = "open"): RqlQuery =
  ## Get all documents between two keys
  newQueryAst(BETWEEN, r, lowerKey, upperKey)
  
  if index != "id":
    result.setOption("index", index)
  if leftBound != "closed":
    result.setOption("left_bound", leftBound)
  if rightBound != "open":
    result.setOption("right_bound", rightBound)

proc filter*[T: MutableDatum|RqlQuery](r: RqlQuery, data: T, default = false): RqlQuery =
  ## Get all the documents for which the given predicate is true
  newQueryAst(FILTER, r)

  result.addArg(r.makeFunc(data))
  if default:
    result.setOption("default", true)

proc filter*[T](r: RqlQuery, f: proc(x: RqlQuery): T, default = false): RqlQuery =
  newQueryAst(FILTER, r)
  result.addArg(funcWrap(f))
  if default:
    result.setOption("default", true)
