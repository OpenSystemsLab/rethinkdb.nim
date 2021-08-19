#--------------------
# Transformations
#--------------------

proc asc*[T: RethinkClient|RqlQuery](r: T, key: string): RqlQuery =
  when r is RethinkClient:
    NEW_QUERY(ASC, key)
  else:
    NEW_QUERY(ASC, r, key)

proc desc*[T: RethinkClient|RqlQuery](r: T, key: string): RqlQuery =
  when r is RethinkClient:
    NEW_QUERY(DESC, key)
  else:
    NEW_QUERY(DESC, r, key)

proc map*[U](r: RqlQuery, f: proc(x: RqlQuery): U): RqlQuery =
  ## Transform each element of one or more sequences by applying a mapping function to them
  NEW_QUERY(MAP, r)
  result.addArg(funcWrap(f))

proc withFields*(r: RqlQuery, n: varargs[string, `$`]): RqlQuery =
  ## Plucks one or more attributes from a sequence of objects,
  ## filtering out any objects in the sequence that do not have the specified fields
  NEW_QUERY(WITH_FIELDS, r)
  for x in n.items():
    result.addArg(x)

proc concatMap*[U](r: RqlQuery, f: proc(x: RqlQuery): U): RqlQuery =
  ## Concatenate one or more elements into a single sequence using a mapping function.
  NEW_QUERY(CONCAT_MAP, r)
  result.addArg(funcWrap(f))

proc orderBy*[T: RqlQuery|string](r: RqlQuery, n: openArray[T], index: RqlQuery = nil): RqlQuery =
  NEW_QUERY(ORDER_BY, r)
  for x in n:
    result.addArg(x)

  if not index.isNil:
    result.setOption("index", index)

proc orderBy*[T: RqlQuery|string](r: RqlQuery, n: openArray[T], index = ""): RqlQuery {.inline.} =
  r.orderBy(n, newDatum(index))

proc orderBy*[T: RqlQuery|string](r: RqlQuery, n: T, index: T = nil): RqlQuery =
  r.orderBy([n], index)

proc orderByIndex*[T: RqlQuery|string](r: RqlQuery, index: T): RqlQuery =
  NEW_QUERY(ORDER_BY, r)
  result.setOption("index", index)
  
proc skip*(r: RqlQuery, n: int): RqlQuery =
  NEW_QUERY(SKIP, r, n)

proc limit*(r: RqlQUery, n: int): RqlQuery =
  NEW_QUERY(LIMIT, r, n)

proc slice*(r: RqlQuery, startIndex: int, endIndex = 0, leftBound = "closed", rightBound = "open"): RqlQuery =
  NEW_QUERY(SLICE_R, r, startIndex)
  if endIndex != 0:
    result.addArg(endIndex)

  if leftBound != "closed":
    result.setOption("left_bound", leftBound)

  if rightBound != "open":
    result.setOption("right_bound", rightBound)

proc nth*(r: RqlQuery, n: int): RqlQUery =
  NEW_QUERY(NTH, r, n)

proc offsetOf*[T](r: RqlQuery, t: T): RqlQuery =
  NEW_QUERY(OFFSETS_OF, r, t)

proc isEmpty*(r: RqlQuery): RqlQuery =
  NEW_QUERY(IS_EMPTY, r)

proc union*(r: RqlQuery, n: varargs[RqlQuery]): RqlQUery =
  NEW_QUERY(UNION, r)
  for x in n:
    result.addArg(x)

proc sample*[T: int|float](r: RqlQuery, n: T): RqlQuery =
  NEW_QUERY(SAMPLE, r, n)
