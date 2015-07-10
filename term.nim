import json

import datum
import ql2

type      
  Term* = ref object of RootObj
    case tt*: TermType
    of DATUM:
      datum*: MutableDatum
    else:
      args*: seq[Term]
      options*: MutableDatum

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

proc `$`*(t: Term): string =
  result = $(%t)

proc `@`*(s: string): Term =
  result = newTerm(DATUM)
  result.datum = &s

proc `@`*(b: bool): Term =
  result = newTerm(DATUM)
  result.datum = &b

proc `@`*(n: int): Term =
  result = newTerm(DATUM)
  result.datum = &n

proc `@`*(a: openArray[MutableDatum]): Term =
  result = newTerm(DATUM)
  result.datum = &a

proc `@`*(a: seq[MutableDatum]): Term =
  result = newTerm(DATUM)
  result.datum = &a
  
  
proc `@`*(o: openArray[tuple[key: string, val: MutableDatum]]): Term =
  result = newTerm(DATUM)
  result.datum = &o
