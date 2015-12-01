proc group*[T: RqlQuery|string](r: RqlQuery, n: openArray[T], index: RqlQuery = nil, multi = false): RqlQuery =
  newQueryAst(GROUP, r)
  for x in n:
    result.addArg(x)

  if not index.isNil:
    result.setOption("index", index)
  if multi:
    result.setOption("multi", multi)

proc group*[T: RqlQuery|string](r: RqlQuery, n: openArray[T], index = "", multi = false): RqlQuery {.inline.} =
  r.group(n, newDatum(index), multi)

proc ungroup*(r: RqlQuery): RqlQuery =
  newQueryAst(UNGROUP, r)

proc reduce*[T](r: RqlQuery, f: proc(x, y: RqlQuery): T): RqlQuery =
  newQueryAst(REDUCE, r)
  result.addArg(funcWrap(f))

proc count*[T](r: T): RqlQuery =
  newQueryAst(COUNT, r)

proc count*[T](r: T, v: int): RqlQuery =
  newQueryAst(COUNT, r, v)

proc count*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  newQueryAst(COUNT, r)
  result.addArg(funcWrap(f))

proc sum*[T](r: T, f = ""): RqlQuery =
  newQueryAst(SUM, r)
  if f != "":
    result.addArg(f)

proc sum*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  newQueryAst(SUM, r)
  result.addArg(funcWrap(f))

proc avg*[T](r: T, f = ""): RqlQuery=
  newQueryAst(AVG, r)
  if f != "":
    result.addArg(f)

proc avg*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  newQueryAst(AVG, r)
  result.addArg(funcWrap(f))

proc min*[T](r: T, f = "", index = ""): RqlQuery=
  newQueryAst(MIN, r)
  if f != "":
    result.addArg(f)
  if index != "":
    result.setOption("index", index)

proc min*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  newQueryAst(MIN, r)
  result.addArg(funcWrap(f))

proc max*[T](r: T, f = "", index = ""): RqlQuery=
  newQueryAst(MAX, r)
  if f != "":
    result.addArg(f)
  if index != "":
    result.setOption("index", index)

proc max*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  newQueryAst(MAX, r)
  result.addArg(funcWrap(f))

proc distinctR*[T](r: T, index = ""): RqlQuery =
  newQueryAst(DISTINCT, r)
  if index != "":
    result.setOption("index", index)

proc contains*[T](r: RqlQuery, n: varargs[proc(x: RqlQuery): T]): RqlQuery =
  newQueryAst(CONTAINS, r)
  result.addArg(funcWrap(n))

proc contains*[T](r: RqlQuery, n: varargs[T]): RqlQuery =
  newQueryAst(CONTAINS, r)
  for x in n:
    result.addArg(x)
