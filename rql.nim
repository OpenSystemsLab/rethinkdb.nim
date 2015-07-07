import rethinkdb
import ql2
import strtabs
import strutils

type
  MutableDatum = ref object of RootObj
    case kind*: DatumType
    of R_STR:
      str*: string
    of R_BOOL:
      bval*: bool
    of R_NUM:
      num*: int
    else:
      discard
      
  Term = ref object of RootObj
    case tt*: TermType
    of DATUM:
      mutableDatum*: MutableDatum
    else:
      args*: seq[Term]
      options*: StringTableRef

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
    result.options = newStringTable()

proc `$`(term: Term): string =
  result = ""
  case term.tt
  of DATUM:
    var val = ""
    case term.mutableDatum.kind
    of R_STR:
      val = "\"" & term.mutableDatum.str & "\""
    of R_BOOL:
      val = $term.mutableDatum.bval
    of R_NUM:
      val = $term.mutableDatum.num
    else:
      val = "{}"
    result.add("[$#]" % [val])
  else:
    var val = ""
    for x in term.args:
      val.add($x)      
    #TODO options
    var opts = ""  
    #opts.add(", {}")
    result.add("[$#, $#$#]," % [$term.tt, val, opts])
  #result.add("]")
      
proc newMutableDatum(k: DatumType): MutableDatum =
  new(result)
  result.kind = k

proc newRqlString*(s: string): RqlString =
  new(result)  
  result.term = newTerm(DATUM)
  result.term.mutableDatum = newMutableDatum(R_STR)
  result.term.mutableDatum.str = s
    
proc run*(r: RQL) =
  echo r.term
  
proc db*(r: RethinkClient, db: string): RqlDatabase =
  new(result)
  result.conn = r
  result.term = newTerm(DB)
  result.term.args.add(newRqlString(db).term)

proc table*(rdb: RqlDatabase, table: string): RqlTable =
  new(result)
  result.conn = rdb.conn
  result.term = newTerm(TABLE)
  result.term.args.add(rdb.term)
  result.term.args.add(newRqlString(table).term)
  
  

var r = newRethinkClient()
r.db("blog").table("pins").run() #.filter({name: "Hello World!"}).run()
