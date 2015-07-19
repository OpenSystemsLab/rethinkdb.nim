
## This module provides all high-level API for query and manipulate data

import asyncdispatch
import strtabs
import strutils
import json
import typetraits
import tables

import ql2
import datum
import connection
import utils
import types

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

proc run*(r: RqlQuery, c: RethinkClient = nil): Future[JsonNode] {.async.} =
  ## Run a query on a connection, returning a `JsonNode` contains single JSON result or an JsonArray, depending on the query.
  var c = c
  if c.isNil:
    c = defaultClient
  if c.isNil:
    raise newException(RqlClientError, "r.run() must be given a connection to run on.")

  if not c.isConnected:
    raise newException(RqlClientError, "Connection is closed.")

  await c.startQuery(r)
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

#proc `@`*(r: RqlQuery): Term {.inline.} =
#  result = r.term

proc addArg*[T](r: RqlQuery, t: T) {.noSideEffect.} =
  when t is RqlQuery:
    r.args.add(t)
  else:
    r.args.add(newDatum(t))

proc setOption*(r: RqlQuery, k: string, v: RqlQuery) {.noSideEffect, inline.} =
  r.optargs[k] = v

proc setOption*[T](r: RqlQuery, k: string, v: T) {.noSideEffect, inline.} =
  r.optargs[k] = newDatum(v)



proc makeArray*[T](t: T): RqlQuery =
  newQueryAst(MAKE_ARRAY)
  result.addArg(newDatum(t))

proc makeVar(i: int): RqlQuery =
  newQueryAst(VAR)
  result.addArg(newDatum(i))

proc funcWrap[T](f: proc(x: RqlQuery): T): RqlQuery =
  ## Wraper for anonymous function
  newQueryAst(FUNC)

  let v1 = makeVar(1)
  result.addArg(makeArray(1))
  result.addArg(f(v1))

proc funcWrap[T](f: proc(x: RqlQuery, y: RqlQuery): T): RqlQuery =
  newQueryAst(FUNC)

  let v1 = makeVar(1)
  let v2 = makeVar(2)

  result.addArg(&*[1, 2])
  result.addArg(f(v1, v2))

proc makeFunc*[T](r: T, f: RqlQuery): RqlQuery =
  ## Call an anonymous function using return values from other ReQL commands or queries as arguments.
  ##
  ## renamed from `do` function to avoid keyword conflict
  var varId {.global.} = 0

  varId.inc

  result = newQuery(FUNC)
  #TODO args count
  result.addArg(makeArray(varId))
  result.addArg(f)

proc `[]`*[T, U](r: T, s: string): U =
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
include queries/document
include queries/math
include queries/structures
