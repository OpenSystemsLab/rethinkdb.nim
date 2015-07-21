#--------------------
# Control structures
#--------------------

proc args*(r: RethinkClient, args: MutableDatum): RqlQuery =
  ## `r.args` is a special term that’s used to splice an array of arguments into another term
  newQueryAst(ARGS, args)

proc binary*(r: RethinkClient, data: BinaryData): RqlQuery =
  ## Encapsulate binary data within a query.
  newQueryAst(BINARY, data)

proc funCall*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  when r is RethinkClient:
    newQueryAst(FUNCALL)
  else:
    newQueryAst(FUNCALL, r)

  result.addArg(funcWrap(f))

proc branch*[T](r: T, test, trueBranch, falseBranch: RqlQuery): RqlQuery =
  newQueryAst(BRANCH, test, trueBranch, falseBranch)

proc forEach*[T](r: RqlQuery, f: proc(x: RqlQuery): T): RqlQuery =
  newQueryAst(FOR_EACH, r)
  result.addArg(funcWrap(f))

proc range*[T](r: T): RqlQuery =
  when r is RethinkClient:
    newQueryAst(RANGE)
  else:
    newQueryAst(RANGE, r)

proc range*[T](r: T, endValue: int): RqlQuery =
  when r is RethinkClient:
    newQueryAst(RANGE)
  else:
    newQueryAst(RANGE, r)
  result.addArg(endValue)

proc range*[T](r: T, startValue, endValue): RqlQuery =
  when r is RethinkClient:
    newQueryAst(RANGE)
  else:
    newQueryAst(RANGE, r)
  result.addArg(startValue)
  result.addArg(endValue)

proc error*(r: RethinkClient, msg: string): RqlQuery =
  newQueryAst(ERROR, msg)

proc default*[T](r: RqlQuery, t: T): RqlQuery =
  newQueryAst(DEFAULT, r, t)

proc expr*[T, U, V](r: T, x: U): V =
  ## Construct a ReQL JSON object from a native object

  #TODO does this really works as expected
  when x is RqlQuery:
    result = x
  else:
    result = newDatum(x)

proc js*(r: RethinkClient, js: string, timeout = 0): RqlQuery =
  ## Create a javascript expression.
  newQueryAst(JAVASCRIPT, js)

proc coerceTo*(r: RqlQuery, x: string): RqlQuery =
  newQueryAst(COERCE_TO, r, x)

proc typeof*(r: RqlQuery): RqlQuery =
  newQueryAst(TYPE_OF, r)

proc info*(r: RqlQuery): RqlQuery =
  newQueryAst(INFO, r)

proc json*(r: RethinkClient, s: string): RqlQuery =
  newQueryAst(JSON, s)

proc toJson*(r: RqlQuery): RqlQuery =
  newQueryAst(TO_JSON_STRING, r)

proc http*(r: RethinkClient, url: string): RqlQuery =
  newQueryAst(HTTP, url)
  #TODO options

proc uuid*(r: RethinkClient): RqlQuery =
  newQueryAst(UUID)
