
## This module provides all high-level API for query and manipulate data
import json, future
import ql2, datum, connection, utils, types


when not compileOption("threads"):
  import asyncdispatch

export `=>`

var defaultClient {.threadvar.}: RethinkClient


proc row*[T: RethinkClient|RqlQuery](r: T): RqlQuery =
  result = new(RqlQuery)
  #raise newException(RqlDriverError, "'r.row' is not callable, use 'r.row[...]' instead")


proc repl*(r: RethinkClient) =
  defaultClient = r

when not compileOption("threads"):
  proc run*(r: RqlQuery, c: RethinkClient = nil, readMode = "single",
            timeFormat = "native", profile = false, durability = "hard", groupFormat = "native",
            noreply = false, db = "", arrayLimit = 100_000, binaryFormat = "native",
            minBatchRows = 8, maxBatchRows = 0, maxBatchBytes = 0, maxBatchSeconds = 0.5,
            firstBatchScaleDownFactor = 4): Future[JsonNode] {.async, discardable.} =
    ## Run a query on a connection, returning a `JsonNode` contains single JSON result or an JsonArray, depending on the query.
    var c = c
    if c.isNil:
      c = defaultClient
    if c.isNil:
      raise newException(RqlClientError, "r.run() must be given a connection to run on.")

    if not c.isConnected:
      raise newException(RqlClientError, "Connection is closed.")

    var options = newTable[string, MutableDatum]()

    if readMode != "single":
      options.add(("read_mode",  &readMode))

    if timeFormat != "native":
      options.add(("time_format",  &timeFormat))

    if profile:
      options.add(("profile",  &profile))

    if durability != "hard":
      options.add(("durability",  &durability))

    if groupFormat != "native":
      options.add(("group_format",  &groupFormat))

    if noreply:
      options.add(("noreply",  &noreply))

    if db != "":
      options.add(("db",  &db))

    if arrayLimit != 100_000:
      options.add(("array_limit",  &arrayLimit))

    if binaryFormat != "native":
      options.add(("binary_format",  &binaryFormat))

    if minBatchRows != 8:
      options.add(("min_batch_rows",  &minBatchRows))

    if maxBatchRows != 0:
      options.add(("max_batch_rows",  &maxBatchRows))

    if maxBatchBytes != 0:
      options.add(("max_batch_bytes",  &maxBatchBytes))

    if maxBatchSeconds != 0.5:
      options.add(("max_batch_seconds",  &maxBatchSeconds))

    if firstBatchScaleDownFactor != 4:
      options.add(("first_batch_scaledown_factor",  &firstBatchScaleDownFactor))

    await c.startQuery(r, options)

    if not noreply:
      var response = await c.readResponse()
      case response.kind
      of SUCCESS_ATOM:
        result = response.data[0]
      of WAIT_COMPLETE:
        discard
      of SUCCESS_SEQUENCE:
        result = response.data
      of SUCCESS_PARTIAL:
        result = newJArray()
        result.add(response.data)
        while response.kind == SUCCESS_PARTIAL:
          await c.continueQuery(response.token)
          response = await c.readResponse()
          result.add(response.data)
          if result.elems.len == 1:
            return result[0]
      of CLIENT_ERROR:
        raise newException(RqlClientError, $response.data[0])
      of COMPILE_ERROR:
        raise newException(RqlCompileError, $response.data[0])
      of RUNTIME_ERROR:
        raise newException(RqlRuntimeError, $response.data[0])
      else:
        raise newException(RqlDriverError, "Unknown response type $#" % [$response.kind])
else:
   proc run*(r: RqlQuery, c: RethinkClient = nil, readMode = "single",
            timeFormat = "native", profile = false, durability = "hard", groupFormat = "native",
            noreply = false, db = "", arrayLimit = 100_000, binaryFormat = "native",
            minBatchRows = 8, maxBatchRows = 0, maxBatchBytes = 0, maxBatchSeconds = 0.5,
            firstBatchScAleDownFactor = 4): JsonNode {.thread, discardable.} =
    ## Run a query on a connection, returning a `JsonNode` contains single JSON result or an JsonArray, depending on the query.
    var c = c
    if c.isNil:
      c = defaultClient
    if c.isNil:
      raise newException(RqlClientError, "r.run() must be given a connection to run on.")

    if not c.isConnected:
      raise newException(RqlClientError, "Connection is closed.")

    var options: seq[MutableDatumPairs]

    if readMode != "single":
      options.add(("read_mode", readMode.toDatum))

    if timeFormat != "native":
      options.add(("time_format",  timeFormat.toDatum))

    if profile:
      options.add(("profile",  profile.toDatum))

    if durability != "hard":
      options.add(("durability",  durability.toDatum))

    if groupFormat != "native":
      options.add(("group_format",  groupFormat.toDatum))

    if noreply:
      options.add(("noreply",  noreply.toDatum))

    if db != "":
      options.add(("db",  db.toDatum))

    if arrayLimit != 100_000:
      options.add(("array_limit",  arrayLimit.toDatum))

    if binaryFormat != "native":
      options.add(("binary_format",  binaryFormat.toDatum))

    if minBatchRows != 8:
      options.add(("min_batch_rows",  minBatchRows.toDatum))

    if maxBatchRows != 0:
      options.add(("max_batch_rows",  maxBatchRows.toDatum))

    if maxBatchBytes != 0:
      options.add(("max_batch_bytes",  maxBatchBytes.toDatum))

    if maxBatchSeconds != 0.5:
      options.add(("max_batch_seconds",  maxBatchSeconds.toDatum))

    if firstBatchScaleDownFactor != 4:
      options.add(("first_batch_scaledown_factor",  firstBatchScaleDownFactor.toDatum))

    c.startQuery(r, options)

    if not noreply:
      var response = c.readResponse()
      case response.kind
      of SUCCESS_ATOM:
        result = response.data[0]
      of WAIT_COMPLETE:
        discard
      of SUCCESS_SEQUENCE:
        result = response.data
      of SUCCESS_PARTIAL:
        result = newJArray()
        result.add(response.data)
        while response.kind == SUCCESS_PARTIAL:
          c.continueQuery(response.token)
          response = c.readResponse()
          result.add(response.data)
          if result.elems.len == 1:
            return result[0]
      of CLIENT_ERROR:
        raise newException(RqlClientError, $response.data[0])
      of COMPILE_ERROR:
        raise newException(RqlCompileError, $response.data[0])
      of RUNTIME_ERROR:
        raise newException(RqlRuntimeError, $response.data[0])

proc makeVar(i: int): RqlQuery =
  NEW_QUERY(VAR)
  result.addArg(newDatum(i))

proc funcWrap[T](f: proc(x: RqlQuery): T): RqlQuery =
  ## Wraper for anonymous function
  NEW_QUERY(FUNC)

  let v1 = makeVar(1)
  result.addArg([1])
  let res = f(v1)
  when res is array:
    var arr = newQuery(MAKE_ARRAY)
    for x in res:
      arr.addArg(x)
    result.addArg(arr)
  else:
    result.addArg(res)

proc funcWrap[T](f: proc(x: RqlQuery, y: RqlQuery): T): RqlQuery =
  NEW_QUERY(FUNC)

  let v1 = makeVar(1)
  let v2 = makeVar(2)

  result.addArg(&*[1, 2])
  let res = f(v1, v2)
  when res is array:
    var arr = newQuery(MAKE_ARRAY)
    for x in res:
      arr.addArg(x)
    result.addArg(arr)
  else:
    result.addArg(res)


proc makeFunc*[T](f: T): RqlQuery =
  ## Call an anonymous function using return values from other ReQL commands or queries as arguments.
  ##
  ## renamed from `do` function to avoid keyword conflict
  var varId {.global.} = 0

  varId.inc

  result = newQuery(FUNC)
  #TODO args count
  result.addArg(&[varId])
  result.addArg(f)

proc `[]`*(r: RqlQuery, s: auto): RqlQuery =
  ## Operator for create row's fields chain
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##  r.row["age"]
  NEW_QUERY(BRACKET, r, s)


include queries/db
include queries/table
include queries/writing
include queries/selecting
include queries/join
include queries/transform
include queries/aggregation
include queries/document
include queries/string
include queries/math
include queries/datetime
include queries/structures
include queries/geospatial
