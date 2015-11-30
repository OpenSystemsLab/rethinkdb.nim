
## This module provides all high-level API for query and manipulate data
import asyncdispatch
import strutils
import json
import tables
import future

import ql2
import datum
import connection
import utils
import types

export newTable
export `=>`

type
  RqlDatabase* = ref object of RqlQuery
    db: string

  RqlTable* = ref object of RqlQuery
    rdb: RqlDatabase
    table: string

  RqlRow* = ref object of RqlQuery
    firstVar: bool # indicate this is the first selector

var
  defaultClient: RethinkClient

proc repl*(r: RethinkClient) =
  defaultClient = r

proc run*(r: RqlQuery, c: RethinkClient = nil, readMode = "single",
          timeFormat = "native", profile = false, durability = "hard", groupFormat = "native",
          noreply = false, db = "", arrayLimit = 100_000, binaryFormat = "native",
          minBatchRows = 8, maxBatchRows = 0, maxBatchBytes = 0, maxBatchSeconds = 0.5,
          firstBatchScaleDownFactor = 4): Future[JsonNode] {.async.} =
  ## Run a query on a connection, returning a `JsonNode` contains single JSON result or an JsonArray, depending on the query.
  var c = c
  if c.isNil:
    c = defaultClient
  if c.isNil:
    raise newException(RqlClientError, "r.run() must be given a connection to run on.")

  if not c.isConnected:
    raise newException(RqlClientError, "Connection is closed.")

  if readMode != "single":
    c.addOption("read_mode", &readMode)

  if timeFormat != "native":
    c.addOption("time_format", &timeFormat)

  if profile:
    c.addOption("profile", &profile)

  if durability != "hard":
    c.addOption("durability", &durability)

  if groupFormat != "native":
    c.addOption("group_format", &groupFormat)

  if noreply:
    c.addOption("noreply", &noreply)

  if db != "":
    c.addOption("db", &db)

  if arrayLimit != 100_000:
    c.addOption("array_limit", &arrayLimit)

  if binaryFormat != "native":
    c.addOption("binary_format", &binaryFormat)

  if minBatchRows != 8:
    c.addOption("min_batch_rows", &minBatchRows)

  if maxBatchRows != 0:
    c.addOption("max_batch_rows", &maxBatchRows)

  if maxBatchBytes != 0:
    c.addOption("max_batch_bytes", &maxBatchBytes)

  if maxBatchSeconds != 0.5:
    c.addOption("max_batch_seconds", &maxBatchSeconds)

  if firstBatchScaleDownFactor != 4:
    c.addOption("first_batch_scaledown_factor", &firstBatchScaleDownFactor)

  await c.startQuery(r)

  if noreply:
    discard c.readResponse()
    return

  var response = await c.readResponse()

  case response.kind
  of SUCCESS_ATOM:
    result = response.data[0]
  of WAIT_COMPLETE:
    discard
  of SUCCESS_PARTIAL, SUCCESS_SEQUENCE:
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
    raise newException(RqlDriverError, "Unknow response type $#" % [$response.kind])

proc makeVar(i: int): RqlQuery =
  newQueryAst(VAR)
  result.addArg(newDatum(i))

proc funcWrap[T](f: proc(x: RqlQuery): T): RqlQuery =
  ## Wraper for anonymous function
  newQueryAst(FUNC)

  let v1 = makeVar(1)
  result.addArg(&[1])
  let res = f(v1)
  when res is array:
    var arr = newQuery(MAKE_ARRAY)
    for x in res:
      arr.addArg(x)
    result.addArg(arr)
  else:
    result.addArg(res)

proc funcWrap[T](f: proc(x: RqlQuery, y: RqlQuery): T): RqlQuery =
  newQueryAst(FUNC)

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


proc makeFunc*[T](r: T, f: RqlQuery): RqlQuery =
  ## Call an anonymous function using return values from other ReQL commands or queries as arguments.
  ##
  ## renamed from `do` function to avoid keyword conflict
  var varId {.global.} = 0

  varId.inc

  result = newQuery(FUNC)
  #TODO args count
  result.addArg(&[varId])
  result.addArg(f)

proc `[]`*[T](r: T, s: string): auto =
  ## Operator for create row's fields chain
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##  r.row["age"]
  when r is RqlRow:
    if r.firstVar:
      r.addArg(newDatum(s))
      r.firstVar = false
      result = r
    else:
      newQueryAst(BRACKET, r, s)
  #when r is RqlVariable:
  #  result = r.row[s]
  else:
    result = r.row[s]


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
