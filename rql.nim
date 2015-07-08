import asyncdispatch
import strtabs
import strutils
import json

import connection
import ql2
import datum

type      
  Term = ref object of RootObj
    case tt*: TermType
    of DATUM:
      datum*: MutableDatum
    else:
      args*: seq[Term]
      options*: MutableDatum

  RQL* = ref object of RootObj
    conn*: RethinkClient
    term*: Term

  RqlDatum = ref RQL

  RqlString* = ref object of RqlDatum

  RqlDatabase* = ref object of RQL
    db*: string

  RqlTable* = ref object of RQL
    rdb*: RqlDatabase
    table*: string
    
  RqlQuery* = ref object of RQL
    discard

proc newTerm*(tt: TermType): Term =
  new(result)
  result.tt = tt
  case tt
  of DATUM:
    discard
  else:
    result.args = @[]
    
proc `%`*(term: Term): JsonNode {.procvar.} =
  case term.tt
  of DATUM:
    result = %term.datum
  else:
    result = newJArray()
    result.add(newJInt(term.tt.ord))
    var j = newJArray()
    for x in term.args:      
      j.add(%x)
    result.add(j)
    if not term.options.isNil:
      result.add(%term.options)

proc `$`(t: Term): string =
  result = $(%t)
  
proc newRqlString*(s: string): RqlString =
  new(result)  
  result.term = newTerm(DATUM)
  result.term.datum = newStringDatum(s)
    
proc run*(r: RQL) {.async.} =
  await r.conn.connect()
  var j = newJArray()
  j.add(newJInt(START.ord))
  j.add(%r.term)
  j.add(newJObject())
  await r.conn.sendQuery($j)
  
proc db*(r: RethinkClient, db: string): RqlDatabase =
  new(result)
  result.conn = r
  result.term = newTerm(DB)
  result.term.args.add(newRqlString(db).term)

proc table*(r: RqlDatabase, table: string): RqlTable =
  new(result)
  result.conn = r.conn
  result.term = newTerm(TABLE)
  result.term.args.add(r.term)
  result.term.args.add(newRqlString(table).term)

proc filter*(r: RqlTable, data: openArray[tuple[k: string, v: MutableDatum]]): RqlQuery =
  new(result)
  result.conn = r.conn
  result.term = newTerm(FILTER)
  result.term.args.add(r.term)
  result.term.options = newStringDatum("{name: 'Hello'}")
 
