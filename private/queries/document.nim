#--------------------
# Document manipulation
#--------------------

proc pluck*[T](r: T, n: varargs[string]): RqlQuery =
  NEW_QUERY(PLUCK, r)
  for x in n:
    result.addArg(x)

proc withoutR*[T](r: T, n: varargs[string]): RqlQuery =
  NEW_QUERY(WITHOUT_R, r)
  for x in n:
    result.addArg(x)

proc merge*[T](r: T, n: varargs[RqlQuery]): RqlQuery =
  NEW_QUERY(MERGE, r)
  for x in n:
    result.addArg(x)

proc merge*[T, U](r: T, n: varargs[proc(x: RqlQuery): U]): RqlQuery =
  NEW_QUERY(MERGE, r)
  for f in n:
    result.addArg(funcWrap(f))

proc append*[T](r: RqlQuery, t: T): RqlQuery =
  NEW_QUERY(APPEND, r, t)

proc prepend*[T](r: RqlQuery, t: T): RqlQuery =
  NEW_QUERY(PREPEND, r, t)

proc difference*[T](r: RqlQuery, n: openArray[T]): RqlQuery =
  NEW_QUERY(DIFFERENCE, r, n)

proc setInsert*[T](r: RqlQuery, t: T): RqlQuery =
  NEW_QUERY(SET_INSERT, r, t)

proc setUnion*[T](r: RqlQuery, t: T): RqlQuery =
  NEW_QUERY(SET_UNION, r, t)

proc setIntersection*[T](r: RqlQuery, t: T): RqlQuery =
  NEW_QUERY(SET_INTERSECTION, r, t)

proc setDifference*[T](r: RqlQuery, t: T): RqlQuery =
  NEW_QUERY(SET_DIFFERENCE, r, t)

proc hasFields*[T](r: RqlQuery, n: varargs[T]): RqlQuery =
  NEW_QUERY(HAS_FIELDS, r)
  for x in n:
    result.addArg(x)

proc spliceAt*[T](r: RqlQuery, index: int, t: T): RqlQuery =
  NEW_QUERY(SPLICE_AT, r, index, t)

proc deleteAt*(r: RqlQuery, index: int, endIndex = 0): RqlQuery =
  NEW_QUERY(DELETE_AT, r, index)
  if endIndex != 0:
    result.addArg(endIndex)

proc changeAt*[T](r: RqlQuery, index: int, t: T): RqlQuery =
  NEW_QUERY(CHANGE_AT, r, index, t)

proc keys*(r: RqlQuery): RqlQuery =
  NEW_QUERY(KEYS, r)

proc obj*[T](r: T, n: varargs[MutableDatum, `&`]): RqlQuery =
  NEW_QUERY(OBJECT_R)
  for x in n:
    result.addArg(x)
