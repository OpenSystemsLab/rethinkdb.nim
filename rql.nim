
## This module provides all high-level API for query and manipulate data

import asyncdispatch
import strtabs
import strutils
import json
import typetraits

import ql2
import term
import datum
import connection
import utils

type
  RqlQuery* = ref object of RootObj
    conn: RethinkClient
    term: Term

  RqlDatabase* = ref object of RqlQuery
    db: string

  RqlTable* = ref object of RqlQuery
    rdb: RqlDatabase
    table: string

  RqlRow* = ref object of RqlQuery
    firstVar: bool # indicate this is the first selector

  RqlFunction* = ref object of RqlQuery
  RqlVariable* = ref object of RqlQuery
    id: int



proc run*(r: RqlQuery): Future[JsonNode] {.async.} =
  ## Run a query on a connection, returning a `JsonNode` contains single JSON result or an JsonArray, depending on the query.
  if not r.conn.isConnected:
    await r.conn.connect()
  await r.conn.startQuery(r.term)
  var response = await r.conn.readResponse()

  case response.kind
  of SUCCESS_ATOM:
    result = response.data[0]
  of WAIT_COMPLETE:
    discard
  of SUCCESS_PARTIAL, SUCCESS_SEQUENCE:
    result = newJArray()
    result.add(response.data)
    while response.kind == SUCCESS_PARTIAL:
      await r.conn.continueQuery(response.token)
      response = await r.conn.readResponse()
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

proc `@`*(r: RqlQuery): Term {.inline.} =
  result = r.term

proc addArg*(r: RqlQuery, t: Term) {.noSideEffect, inline.} =
  if not t.isNil:
    r.term.args.add(t)

proc setOptions*(r: RqlQuery, m: MutableDatum) {.noSideEffect, inline.} =
  r.term.options = m

proc makeArray*[T](a: T): Term {.inline.} =
  result = newTerm(MAKE_ARRAY)
  result.args.add(@a)

proc makeObj*[T](r: RethinkClient, o: T): RqlQuery {.inline.} =
  result = newTerm(MAKE_OBJ)
  result.args.add(@o)

proc makeVar(i: int): Term {.inline.} =
  result = newTerm(VAR)
  result.args.add(@i)

proc hasImplicitVar*[T: RqlQuery|Term](t: T): bool =
  result = false
  when t is RqlQuery:
    result = t.term.hasImplicitVar
  else:
    if t.tt == IMPLICIT_VAR:
      result = true
    else:
      for x in t.args:
        if x.hasImplicitVar:
          result true
          break

proc funcWrap[T](f: proc(x: RqlVariable): T): Term =
  ## Wraper for anonymous function
  var varId = 1

  result = newTerm(FUNC)
  var v1 = makeVar(varId)

  result.args.add(makeArray(varId))

  var b1 = newTerm(BRACKET)
  b1.args.add(v1)

  var arg1: RqlVariable
  new(arg1)
  arg1.id = varId

  let res = f(arg1)

  echo "========================="
  echo name(type(res))
  echo "========================="

  when res is RqlVariable:   # the anonymous function return the current row
    result.args.add(v1)      # lambda x: x
  #when res is Term:
  #  b1.args.add(res)
  when res is RqlQuery:
    result.args.add(res.term)
  #when res is RqlQuery:
  #  b1.args.add(res.term)
   # result.args.add(b1)
  when res is MutableDatum:
    b1.args.add(@res)
    result.args.add(b1)
  else:
    discard

proc makeFunc*[T: RethinkClient|RqlQuery](r: T, f: RqlQuery): RqlQuery =
  ## Call an anonymous function using return values from other ReQL commands or queries as arguments.
  ##
  ## renamed from `do` function to avoid keyword conflict
  var varId {.global.} = 0

  varId.inc

  new(result)
  result.conn = r.conn
  result.term = newTerm(FUNC)
  #TODO args count
  result.addArg(makeArray(varId))
  result.addArg(f.term)

proc datumTerm[T, U](r: T, t: U): RqlQuery =
  new(result)
  result.conn = r.conn
  result.term = t


proc `[]`*[T, U](r: T, s: string): U =
  ## Operator for create row's fields chain
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##  r.row["age"]
  when r is RqlRow:
    if r.firstVar:
      r.addArg(@s)
      r.firstVar = false
      result = r
    else:
      ast(r, BRACKET, s)
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
