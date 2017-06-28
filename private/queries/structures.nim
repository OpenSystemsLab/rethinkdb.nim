#--------------------
# Control structures
#--------------------

proc args*(r: RethinkClient, args: MutableDatum): RqlQuery =
  ## `r.args` is a special term that’s used to splice an array of arguments into another term
  NEW_QUERY(ARGS, args)

proc binary*(r: RethinkClient, data: BinaryData): RqlQuery =
  ## Encapsulate binary data within a query.
  NEW_QUERY(BINARY, data)

proc funCall*[T, U](r: T, f: proc(x: RqlQuery): U): RqlQuery =
  when r is RethinkClient:
    NEW_QUERY(FUNCALL)
  else:
    NEW_QUERY(FUNCALL, r)

  result.addArg(funcWrap(f))

proc branch*[T](r: T, test, trueBranch, falseBranch: RqlQuery): RqlQuery =
  NEW_QUERY(BRANCH, test, trueBranch, falseBranch)

proc forEach*[T](r: RqlQuery, f: proc(x: RqlQuery): T): RqlQuery =
  NEW_QUERY(FOR_EACH, r)
  result.addArg(funcWrap(f))

proc range*[T](r: T): RqlQuery =
  when r is RethinkClient:
    NEW_QUERY(RANGE)
  else:
    NEW_QUERY(RANGE, r)

proc range*[T](r: T, endValue: int): RqlQuery =
  when r is RethinkClient:
    NEW_QUERY(RANGE)
  else:
    NEW_QUERY(RANGE, r)
  result.addArg(endValue)

proc range*[T](r: T, startValue, endValue: int): RqlQuery =
  when r is RethinkClient:
    NEW_QUERY(RANGE)
  else:
    NEW_QUERY(RANGE, r)
  result.addArg(startValue)
  result.addArg(endValue)

proc error*(r: RethinkClient, msg: string): RqlQuery =
  NEW_QUERY(ERROR, msg)

proc default*[T](r: RqlQuery, t: T): RqlQuery =
  NEW_QUERY(DEFAULT, r, t)

proc expr*[T: RethinkClient|RqlQuery](r: T, x: auto): RqlQuery =
  ## Construct a ReQL JSON object from a native object

  #TODO does this really works as expected
  when x is RqlQuery:
    result = x
  else:
    result = newDatum(x)

proc js*(r: RethinkClient, js: string, timeout = 0): RqlQuery =
  ## Create a javascript expression.
  NEW_QUERY(JAVASCRIPT, js)

proc coerceTo*(r: RqlQuery, x: string): RqlQuery =
  NEW_QUERY(COERCE_TO, r, x)

proc typeof*(r: RqlQuery): RqlQuery =
  NEW_QUERY(TYPE_OF, r)

proc info*(r: RqlQuery): RqlQuery =
  NEW_QUERY(INFO, r)

proc json*(r: RethinkClient, s: string): RqlQuery =
  NEW_QUERY(JSON, s)

proc toJson*(r: RqlQuery): RqlQuery =
  NEW_QUERY(TO_JSON_STRING, r)

proc http*(r: RethinkClient, url: string): RqlQuery =
  NEW_QUERY(HTTP, url)
  #TODO options

proc uuid*(r: RethinkClient): RqlQuery =
  NEW_QUERY(UUID)
