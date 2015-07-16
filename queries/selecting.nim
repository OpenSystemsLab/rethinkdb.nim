#--------------------
# Selecting data
#--------------------

proc db*(r: RethinkClient, db: string): RqlDatabase =
  ## Reference a database.
  ast(r, DB, db)

proc table*[T: RethinkClient|RqlDatabase](r: T, t: string): RqlTable =
  ## Select all documents in a table
  ast(r, TABLE, t)

proc get*[T: int|string](r: RqlTable, t: T): RqlQuery =
  ## Get a document by primary key
  ast(r, GET, t)

proc getAll*[T: int|string](r: RqlTable, args: openArray[T], index = ""): RqlQuery =
  ## Get all documents where the given value matches the value of the requested index
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##  # with primary index
  ##  r.table("posts").getAll([1, 1]).run()
  ##  # with secondary index
  ##  r.table("posts").getAll(["nim", "lang"], "tags").run()
  ast(r, GET_ALL)
  for x in args:
    result.addArg(@x)

  if index != "":
    result.setOptions(&*{"index": index})

proc between*(r: RqlTable, lowerKey, upperKey: MutableDatum, index = "id", leftBound = "closed", rightBound = "open"): RqlQuery =
  ## Get all documents between two keys
  ast(r, BETWEEN, lowerKey, upperKey)
  result.setOptions(&*{"index": index, "left_bound": leftBound, "right_bound": rightBound})

proc filter*[T: MutableDatum|RqlQuery](r: RqlQuery, data: T, default = false): RqlQuery =
  ## Get all the documents for which the given predicate is true
  ast(r, FILTER)
  when data is MutableDatum:
    result.addArg(@data)
  else:
    var f = r.makeFunc(data)
    result.addArg(f.term)
  if default:
    result.setOptions(&*{"default": true})

  #TODO filter by anonymous functions
