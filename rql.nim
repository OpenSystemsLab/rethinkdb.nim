import asyncdispatch
import strtabs
import strutils
import json


type      
  RQL* = ref object of RootObj
    conn*: RethinkClient
    term*: Term

  RqlDatum = ref object of RQL

  RqlDatabase* = ref object of RQL
    db*: string

  RqlTable* = ref object of RQL
    rdb*: RqlDatabase
    table*: string
    
  RqlQuery* = ref object of RQL
    discard
      
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
  result = newJArray()
  await r.conn.connect()
  await r.conn.startQuery(r.term)
  var response = await r.conn.readResponse()
  
  result.add(response.data)
  while response.kind == SUCCESS_PARTIAL:
    await r.conn.continueQuery(response.token)
    response = await r.conn.readResponse()
    result.add(response.data)
  
proc db*(r: RethinkClient, db: string): RqlDatabase =
  new(result)
  result.conn = r
  result.term = newTerm(DB)
  result.term.args.add(%db)

proc dbList*(r: RethinkClient): RqlQuery =
  new(result)
  result.conn = r
  result.term = newTerm(DB_LIST)
  
proc table*(r: RqlDatabase, table: string): RqlTable =
  new(result)
  result.conn = r.conn
  result.term = newTerm(TABLE)
  result.term.args.add(r.term)
  result.term.args.add(%table)
  
proc filter*(r: RqlTable, data: openArray[tuple[key: string, val: MutableDatum]]): RqlQuery =
  new(result)
  result.conn = r.conn
  result.term = newTerm(FILTER)
  result.term.args.add(r.term) 
  result.term.args.add(%data)
