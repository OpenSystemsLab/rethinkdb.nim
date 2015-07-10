
## This module provides all high-level API for query and manipulate data 

import asyncdispatch
import strtabs
import strutils
import json

import ql2
import term
import datum
import connection


type      
  RqlQuery* = ref object of RootObj
    conn*: RethinkClient
    term*: Term

  RqlDatabase* = ref object of RqlQuery
    db*: string

  RqlTable* = ref object of RqlQuery
    rdb*: RqlDatabase
    table*: string
    
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
  of CLIENT_ERROR:
    raise newException(RqlClientError, $response.data[0])
  of COMPILE_ERROR:
    raise newException(RqlCompileError, $response.data[0])
  of RUNTIME_ERROR:
    raise newException(RqlRuntimeError, $response.data[0])
  else:
    raise newException(RqlDriverError, "Unknow response type $#" % [$response.kind])

template ast(r: static[RqlQuery], tt: static[TermType]): stmt {.immediate.} =
  new(result)
  result.conn = r.conn
  result.term = newTerm(tt)
  if not r.term.isNil:
    result.term.args.add(r.term)

proc db*(r: RethinkClient, db: string): RqlDatabase =
  ## Reference a database.    
  ast(r, DB)
  result.term.args.add(@db)
  
proc dbCreate*(r: RethinkClient, db: string): RqlQuery =
  ## Create a table  
  ast(r, DB_CREATE)
  result.term.args.add(@db)

proc dbDrop*(r: RethinkClient, db: string): RqlQuery =
  ## Drop a database
  ast(r, DB_DROP)
  result.term.args.add(@db)

proc dbList*(r: RethinkClient): RqlQuery =
  ## List all database names in the system. The result is a list of strings.
  ast(r, DB_LIST)

proc tableCreate*[T: RethinkClient|RqlDatabase](r: T, t: string): RqlQuery =
  ## Create a table
  #TODO create options
  ast(r, TABLE_CREATE)
  result.term.args.add(@t)
  
proc tableDrop*[T: RethinkClient|RqlDatabase](r: T, t: string): RqlQuery =
  ## Drop a table
  ast(r, TABLE_DROP)
  result.term.args.add(@t)

#TODO create index

proc indexDrop*(r: RqlTable, name: string): RqlQuery =
  ## Delete a previously created secondary index of this table  
  ast(r, INDEX_DROP)
  result.term.args.add(@name)

proc indexList*(r: RqlTable): RqlQuery =
  ## List all the secondary indexes of this table.
  ast(r, INDEX_LIST)

proc indexRename*(r: RqlTable, oldName, newName: string, overwrite = false): RqlQuery =
  ## Rename an existing secondary index on a table.
  ## If the optional argument overwrite is specified as True,
  ## a previously existing index with the new name will be deleted and the index will be renamed.
  ## If overwrite is False (the default) an error will be raised
  ## if the new index name already exists.
  ast(r, INDEX_RENAME)
  result.term.args.add(@oldName)
  result.term.args.add(@newName)
  if overwrite:
    result.term.args.add(@true)

proc indexStatus*(r: RqlTable, names: varargs[string]): RqlQuery =
  ## Get the status of the specified indexes on this table,
  ## or the status of all indexes on this table if no indexes are specified.
  ast(r, INDEX_STATUS)
  for name in names:
    result.term.args.add(@name)

proc indexWait*(r: RqlTable, names: varargs[string]): RqlQuery =
  ## Wait for the specified indexes on this table to be ready
  ast(r, INDEX_WAIT)
  for name in names:
    result.term.args.add(@name)

proc changes*(r: RqlTable): RqlQuery =
  ## Return a changefeed, an infinite stream of objects representing changes to a query    
  ast(r, CHANGES)
  
proc table*[T: RethinkClient|RqlDatabase](r: T, t: string): RqlTable =
  ## Select all documents in a table
  ast(r, TABLE)
  result.term.args.add(@t)
  
proc get*[T: int|string](r: RqlTable, t: T): RqlQuery =
  ## Get a document by primary key
  ast(t, GET)
  result.term.args.add(@t)

proc getAll*[T: int|string](r: RqlTable, args: openArray[T], index = ""): RqlTable =
  ## Get all documents where the given value matches the value of the requested index
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##  # with primary index
  ##  r.table("posts").getAll([1, 1]).run()
  ##  # with secondary index
  ##  r.table("posts").getAll(["nim", "lang"], "tags").run()  
  ast(r, GET_ALL)
  for x in args:
    result.term.args.add(@x)

  if index != "":
    result.term.options = &{"index": &index}
  
proc filter*(r: RqlTable, data: openArray[tuple[key: string, val: MutableDatum]]): RqlTable =
  ## Get all the documents for which the given predicate is true
  ast(r, FILTER)
  result.term.args.add(@data)
