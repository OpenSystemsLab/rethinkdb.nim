#--------------------
# Document manipulation
#--------------------

proc pluck*[T](r: T, n: varargs[string]): RqlQuery =
  newQueryAst(PLUCK, r)
  for x in n:
    result.addArg(x)

proc withoutR*[T](r: T, n: varargs[string]): RqlQuery =
  newQueryAst(WITHOUT_R, r)
  for x in n:
    result.addArg(x)

proc merge*[T](r: T, n: varargs[RqlQuery]): RqlQuery =
  newQueryAst(MERGE, r)
  for x in n:
    result.addArg(x)

proc merge*[T, U](r: T, n: varargs[proc(x: RqlQuery): U]): RqlQuery =
  newQueryAst(MERGE, r)
  for f in n:
    result.addArg(funcWrap(f))

proc appendInner(r: RqlQuery): RqlQuery {.inline.} =
  newQueryAst(APPEND, r)

proc append*[T](r: RqlQuery, t: T): RqlQuery =
  result = appendInner(r)
  result.addArg(t)

proc prepend*[T](r: RqlQuery, t: T): RqlQuery =
  newQueryAst(PREPEND, r, t)

proc difference*[T](r: RqlQuery, n: openArray[T]): RqlQuery =
  newQueryAst(DIFFERENCE, r, n)

proc setInsert*[T](r: RqlQuery, t: T): RqlQuery =
  newQueryAst(SET_INSERT, r, t)

proc setUnion*[T](r: RqlQuery, t: T): RqlQuery =
  newQueryAst(SET_UNION, r, t)

proc setIntersection*[T](r: RqlQuery, t: T): RqlQuery =
  newQueryAst(SET_INTERSECTION, r, t)

proc setDifference*[T](r: RqlQuery, t: T): RqlQuery =
  newQueryAst(SET_DIFFERENCE, r, t)

proc hasFields*[T](r: RqlQuery, n: varargs[T]): RqlQuery =
  newQueryAst(HAS_FIELDS, r)
  for x in n:
    result.addArg(x)

proc spliceAt*[T](r: RqlQuery, index: int, t: T): RqlQuery =
  newQueryAst(SPLICE_AT, r, index, t)

proc deleteAt*(r: RqlQuery, index: int, endIndex = 0): RqlQuery =
  newQueryAst(DELETE_AT, r, index)
  if endIndex != 0:
    result.addArg(endIndex)

proc changeAt*[T](r: RqlQuery, index: int, t: T): RqlQuery =
  newQueryAst(CHANGE_AT, r, index, t)

proc keys*(r: RqlQuery): RqlQuery =
  newQueryAst(KEYS, r)

proc obj*[T](r: T, n: varargs[MutableDatum, `&`]): RqlQuery =
  newQueryAst(OBJECT_R)
  for x in n:
    result.addArg(x)
