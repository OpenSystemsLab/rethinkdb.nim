
## This module provides all high-level API for query and manipulate data
import json, sugar
import ql2, datum, connection, utils, types


when not compileOption("threads"):
  import asyncdispatch

export `=>`

var defaultClient {.threadvar.}: RethinkClient


proc row*[T: RethinkClient|RqlQuery](r: T): RqlQuery =
  result = new(RqlQuery)
  #raise newException(RqlDriverError, "'r.row' is not callable, use 'r.row[...]' instead")


proc repl*(r: RethinkClient): RethinkClient {.discardable.} =
  defaultClient = r
  result = r

when not compileOption("threads"):
  proc run*(r: RqlQuery, c: RethinkClient = nil, readMode = "single",
            timeFormat = "native", profile = false, durability = "hard", groupFormat = "native",
            noreply = false, db = "", arrayLimit = 100_000, binaryFormat = "native",
            minBatchRows = 8, maxBatchRows = 0, maxBatchBytes = 0, maxBatchSeconds = 0.5,
            firstBatchScaleDownFactor = 4, callback: proc(data: JsonNode) = nil): Future[JsonNode] {.async, discardable.} =
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
      options.add(("read_mode",  readMode.toDatum))

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
        if callback != nil:
          callback(response.data)
        else:
          result = newJArray()
          result.add(response.data)
        while response.kind == SUCCESS_PARTIAL:
          await c.continueQuery(response.token)
          response = await c.readResponse()
          if callback != nil:
            callback(response.data)
          else:
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
   proc run*(r: RqlQuery, c: RethinkClient = nil, readMode = "single",
            timeFormat = "native", profile = false, durability = "hard", groupFormat = "native",
            noreply = false, db = "", arrayLimit = 100_000, binaryFormat = "native",
            minBatchRows = 8, maxBatchRows = 0, maxBatchBytes = 0, maxBatchSeconds = 0.5,
            firstBatchScAleDownFactor = 4, callback: proc(data: JsonNode) = nil): JsonNode {.thread, discardable.} =
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
        if callback != nil:
          callback(response.data)
        else:
          result = newJArray()
          result.add(response.data)
        while response.kind == SUCCESS_PARTIAL:
          c.continueQuery(response.token)
          response = c.readResponse()
          if callback != nil:
            callback(response.data)
          else:
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

type
  f1 = proc(a1: RqlQuery): RqlQuery
  f2 = proc(a1, a2: RqlQuery): RqlQuery
  f3 = proc(a1, a2, a3: RqlQuery): RqlQuery
  f4 = proc(a1, a2, a3, a4: RqlQuery): RqlQuery


proc funcWrap*[T: f1|f2|f3|f4](f: T): RqlQuery =
  NEW_QUERY(FUNC)

  when T is f1:
    result.addArg(&*[1])
    let res = f(makeVar(1))
  elif T is f2:
    result.addArg(&*[1, 2])
    let res = f(makeVar(1), makeVar(2))
  elif T is f3:
    result.addArg(&*[1, 2, 3])
    let res = f(makeVar(1), makeVar(2), makeVar(3))
  elif T is f4:
    result.addArg(&*[1, 2, 3, 4])
    let res = f(makeVar(1), makeVar(2), makeVar(3), makeVar(4))

  when res is array:
    var arr = newQuery(MAKE_ARRAY)
    for x in res:
      arr.addArg(x)
    result.addArg(arr)
  else:
    result.addArg(res)

proc `[]`*(r: RqlQuery, s: auto): RqlQuery =
  ## Operator for create row's fields chain
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##  r.row["age"]
  NEW_QUERY(BRACKET, r, s)


proc changes*[T](r: T, squash = false, includeStates = false): RqlQuery =
  ## Return a changefeed, an infinite stream of objects representing changes to a query
  NEW_QUERY(CHANGES, r)
  if squash:
    result.setOption("squash", squash)
  if includeStates:
    result.setOption("include_states", includeStates)

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
