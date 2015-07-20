#--------------------
# Document manipulation
#--------------------

proc row*[T](r: T): RqlRow =
  ## Returns the currently visited document
  ##
  ## This proc must be called along with `[]` operator
  newQueryAst(BRACKET)
  result.firstVar = true

  when r is RethinkClient:
    result.addArg(newQuery(IMPLICIT_VAR))
  else:
    result.addArg(r)

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

proc append*[T](r: RqlQuery, t: T): RqlQuery =
  newQueryAst(APPEND, t)

proc prepend*[T](r: RqlQuery, t: T): RqlQuery =
  newQueryAst(PREPEND, t)

proc diffeence*[T](r: RqlQuery, n: openArray[T]): RqlQuery =
  newQueryAst(DIFFERENCE, r, n)
