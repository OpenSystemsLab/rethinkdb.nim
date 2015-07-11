
## This module provides all high-level API for query and manipulate data

import asyncdispatch
import strtabs
import strutils
import json
import macros

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

template ast[T](r: static[T], tt: static[TermType]): stmt {.immediate.} =
  new(result)
  result.conn = r.conn
  result.term = newTerm(tt)
  if not r.term.isNil:
    result.term.args.add(r.term)
#--------------------
# Manipulating databases
#--------------------

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

#--------------------
# Manipulating tables
#--------------------

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

#--------------------
# Writing data
#--------------------

proc insert*(r: RqlTable, data: openArray[MutableDatum], durability="hard", returnChanges=false, conflict="error"): RqlQuery =
  ## Insert documents into a table. Accepts a single document or an array of documents
  ast(r, INSERT)
  result.term.args.add(@data)
  result.term.options = &*{"durability": durability, "return_changes": returnChanges, "conflict": conflict}

proc update*(r: RqlQuery, data: MutableDatum, durability="hard", returnChanges=false, nonAtomic=false): RqlQuery =
  ## Insert documents into a table. Accepts a single document or an array of documents
  ast(r, UPDATE)
  result.term.args.add(@data)
  result.term.options = &*{"durability": durability, "return_changes": returnChanges, "non_atomic": nonAtomic}

proc replace*(r: RqlQuery, data: MutableDatum, durability="hard", returnChanges=false, nonAtomic=false): RqlQuery =
  ## Replace documents in a table. Accepts a JSON document or a ReQL expression,
  ## and replaces the original document with the new one. The new document must have the same primary key as the original document.
  ast(r, REPLACE)
  result.term.args.add(@data)
  result.term.options = &*{"durability": durability, "return_changes": returnChanges, "non_atomic": nonAtomic}

proc delete*(r: RqlQuery, data: MutableDatum, durability="hard", returnChanges=false): RqlQuery =
  ## Delete one or more documents from a table.
  ast(r, DELETE)
  result.term.args.add(@data)
  result.term.options = &*{"durability": durability, "return_changes": returnChanges}

proc sync*(r: RqlQuery, data: MutableDatum): RqlQuery =
  ## `sync` ensures that writes on a given table are written to permanent storage
  ast(r, SYNC)
  result.term.args.add(@data)

#--------------------
# Selecting data
#--------------------

proc db*(r: RethinkClient, db: string): RqlDatabase =
  ## Reference a database.
  ast(r, DB)
  result.term.args.add(@db)

proc table*[T: RethinkClient|RqlDatabase](r: T, t: string): RqlTable =
  ## Select all documents in a table
  ast(r, TABLE)
  result.term.args.add(@t)

proc get*[T: int|string](r: RqlTable, t: T): RqlQuery =
  ## Get a document by primary key
  ast(r, GET)
  result.term.args.add(@t)

proc getAll*[T: int|string](r: RqlTable, args: openArray[T], index = ""): RqlQuery =
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
    result.term.options = &*{"index": index}

proc between*(r: RqlTable, lowerKey, upperKey: MutableDatum, index = "id", leftBound = "closed", rightBound = "open"): RqlQuery =
  ## Get all documents between two keys
  ast(r, BETWEEN)
  result.term.args.add(@lowerKey)
  result.term.args.add(@upperKey)
  result.term.options = &*{"index": index, "left_bound": leftBound, "right_bound": rightBound}

proc filter*(r: RqlQuery, data: MutableDatum, default = false): RqlQuery =
  ## Get all the documents for which the given predicate is true
  ast(r, FILTER)
  result.term.args.add(@data)
  if default:
    result.term.options = &*{"default": true}

  #TODO filter by expr

#--------------------
# Joins
#--------------------

#proc innerJoin*(r: RqlQuery,
#--------------------
# Transformations
#--------------------

proc args*(r: RethinkClient, args: MutableDatum): RqlQuery =
  ## `r.args` is a special term that’s used to splice an array of arguments into another term
  ast(r, ARGS)
  result.term.args.add(@args)

proc binary*(r: RethinkClient, data: BinaryData): RqlQuery =
  ## Encapsulate binary data within a query.
  ast(r, BINARY)
  result.term.args.add(@data)

proc call*(r: RethinkClient, f: Term): RqlQuery =
  ## Call an anonymous function using return values from other ReQL commands or queries as arguments.
  ##
  ## renamed from `do` function to avoid keyword conflict
  ast(r, FUNC)

proc makeObj*(r: RethinkClient, o: MutableDatum): RqlQuery =
  ast(r, MAKE_OBJ)
  result.term.options = o

proc makeArray*(r: RethinkClient, a: MutableDatum): RqlQuery =
  ast(r, MAKE_ARRAY)
  result.term.options = a

proc makeVar*[T](r: RethinkClient, x: T): RqlQuery =
  ast(r, IMPLICIT_VAR)
  #result.term.args.add(@x)

proc expr*[T](r: RethinkClient, x: T): RqlQuery =
  ## Construct a ReQL JSON object from a native object

  #TODO does this really works as expected
  when x is RqlQuery:
    result = x
  when x is MutableDatum:
    case x.kind
    of R_OBJECT:
      result = r.makeObj(x)
    of R_ARRAY:
      result = r.makeArray(x)
    else:
      #TODO cover all cases
      result = r.makeVar(x)
  else:
    result = r.makeVar(x)

proc js*(r: RethinkClient, js: string, timeout = 0): RqlQuery =
  ## Create a javascript expression.
  ast(r, JAVASCRIPT)
  result.term.args.add(@js)

#--------------------
# Document manipulation
#--------------------
