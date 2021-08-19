proc group*[T: RqlQuery|string](r: RqlQuery, n: openArray[T], index: RqlQuery = nil, multi = false): RqlQuery =
  NEW_QUERY(GROUP, r)
  for x in n:
    result.addArg(x)

  if not index.isNil:
    result.setOption("index", index)
  if multi:
    result.setOption("multi", multi)

proc group*[T: RqlQuery|string](r: RqlQuery, n: openArray[T], index = "", multi = false): RqlQuery {.inline.} =
  r.group(n, newDatum(index), multi)

proc ungroup*(r: RqlQuery): RqlQuery =
  NEW_QUERY(UNGROUP, r)

proc reduce*[T](r: RqlQuery, f: proc(x, y: RqlQuery): T): RqlQuery =
  NEW_QUERY(REDUCE, r)
  result.addArg(funcWrap(f))

proc count*[T](r: T): RqlQuery =
  NEW_QUERY(COUNT, r)

proc count*[T](r: T, v: int): RqlQuery =
  NEW_QUERY(COUNT, r, v)

proc count*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  NEW_QUERY(COUNT, r)
  result.addArg(funcWrap(f))

proc sum*[T](r: T, f = ""): RqlQuery =
  NEW_QUERY(SUM, r)
  if f != "":
    result.addArg(f)

proc sum*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  NEW_QUERY(SUM, r)
  result.addArg(funcWrap(f))

proc avg*[T](r: T, f = ""): RqlQuery=
  NEW_QUERY(AVG, r)
  if f != "":
    result.addArg(f)

proc avg*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  NEW_QUERY(AVG, r)
  result.addArg(funcWrap(f))

proc min*[T](r: T, f = "", index = ""): RqlQuery=
  NEW_QUERY(MIN, r)
  if f != "":
    result.addArg(f)
  if index != "":
    result.setOption("index", index)

proc min*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  NEW_QUERY(MIN, r)
  result.addArg(funcWrap(f))

proc max*[T](r: T, f = "", index = ""): RqlQuery=
  NEW_QUERY(MAX, r)
  if f != "":
    result.addArg(f)
  if index != "":
    result.setOption("index", index)

proc max*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  NEW_QUERY(MAX, r)
  result.addArg(funcWrap(f))

proc distinctR*[T](r: T, index = ""): RqlQuery =
  NEW_QUERY(DISTINCT, r)
  if index != "":
    result.setOption("index", index)

proc contains*[T](r: RqlQuery, n: varargs[proc(x: RqlQuery): T]): RqlQuery =
  NEW_QUERY(CONTAINS, r)
  result.addArg(funcWrap(n))

proc contains*[T](r: RqlQuery, n: varargs[T]): RqlQuery =
  NEW_QUERY(CONTAINS, r)
  for x in n:
    result.addArg(x)
