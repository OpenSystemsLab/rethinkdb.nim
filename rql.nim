import asyncdispatch
import strtabs
import strutils
import json


type      
  RQL* = ref object of RootObj
    conn*: RethinkClient
    term*: Term


  RqlDatabase* = ref object of RQL
    db*: string

  RqlTable* = ref object of RQL
    rdb*: RqlDatabase
    table*: string
    
  RqlQuery* = ref object of RQL
    discard

# RqlDatum = ref object of RQL
      
#proc RStringTerm*(s: string): RqlDatum =
#  new(result)  
#  result.term = newTerm(DATUM)
#  result.term.datum = &s

#proc RBoolTerm*(b: bool): RqlDatum =
#  new(result)
#  result.term = newTerm(DATUM)
#  result.term.datum = &b

#proc RNumTerm*(n: int): RqlDatum =
#  new(result)
#  result.term = newTerm(DATUM)
#  result.term.datum = &n

#proc RArrayTerm*(a: openArray[MutableDatum]): RqlDatum =
#  new(result)
#  result.term = newTerm(DATUM)
#  result.term.datum = &a
  
#proc RObjectTerm*(o: openArray[tuple[key: string, val: MutableDatum]]): RqlDatum =
#  new(result)
#  result.term = newTerm(DATUM)
#  result.term.datum = &o
  
proc run*(r: RQL): Future[JsonNode] {.async.} =
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
    result.add(response.data[0])
    while response.kind == SUCCESS_PARTIAL:
      await r.conn.continueQuery(response.token)
      response = await r.conn.readResponse()
      result.add(response.data[0])
  of CLIENT_ERROR:
    raise newException(RqlClientError, $response.data[0])
  of COMPILE_ERROR:
    raise newException(RqlCompileError, $response.data[0])
  of RUNTIME_ERROR:
    raise newException(RqlRuntimeError, $response.data[0])
  else:
    raise newException(RqlDriverError, "Unknow response type $#" % [$response.kind])
  
proc db*(r: RethinkClient, db: string): RqlDatabase =
  ## Reference a database.    
  new(result)
  result.conn = r
  result.term = newTerm(DB)
  result.term.args.add(%db)
  
proc dbCreate*(r: RethinkClient, table: string): RqlQuery =
  ## Create a table  
  new(result)
  result.conn = r
  result.term = newTerm(DB_CREATE)
  result.term.args.add(%table)

proc dbDrop*(r: RethinkClient, table: string): RqlQuery =
  ## Drop a database
  new(result)
  result.conn = r
  result.term = newTerm(DB_DROP)
  result.term.args.add(%table)

proc dbList*(r: RethinkClient): RqlQuery =
  ## List all database names in the system. The result is a list of strings.
  new(result)
  result.conn = r
  result.term = newTerm(DB_LIST)

proc table*(r: RethinkClient, table: string): RqlTable =
  new(result)
  result.conn = r
  result.term = newTerm(TABLE)
  result.term.args.add(%table)
  
proc table*(r: RqlDatabase, table: string): RqlTable =
  ## Select all documents in a table
  new(result)
  result.conn = r.conn
  result.term = newTerm(TABLE)
  result.term.args.add(r.term)
  result.term.args.add(%table)

proc get*(r: RQL, id: string): RqlQuery =
  ## Get a document by primary key
  new(result)
  result.conn = r.conn
  result.term = newTerm(GET)
  result.term.args.add(r.term)
  result.term.args.add(%id)
  
proc filter*(r: RQL, data: openArray[tuple[key: string, val: MutableDatum]]): RqlQuery =
  ## Get all the documents for which the given predicate is true
  new(result)
  result.conn = r.conn
  result.term = newTerm(FILTER)
  result.term.args.add(r.term) 
  result.term.args.add(%data)
