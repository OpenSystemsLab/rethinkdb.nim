import json
import tables
import macros
import times
import base64

import ql2
type
  RqlQuery {.pure.} = object
  BinaryData* = ref object of RootObj
    data*: string

  MutableDatum* = ref object of RootObj
    case kind*: DatumType
    of R_NULL:
      discard
    of R_BOOLEAN:
      bval*: bool
    of R_INTEGER:
      num*: int64
    of R_FLOAT:
      fval*: float64
    of R_STRING, R_JSON:
      str*: string
    of R_ARRAY:
      arr*: seq[MutableDatum]
    of R_OBJECT:
      obj*: TableRef[string, MutableDatum]
    of R_BINARY:
      binary*: BinaryData
    of R_TIME:
      time*: TimeInfo
    of R_TERM:
      term*: RqlQuery

proc `%`*(m: MutableDatum): JsonNode =
  if m.isNil:
    return newJNull()
  case m.kind
  of R_STRING:
    result = newJString(m.str)
  of R_BOOLEAN:
    result = newJBool(m.bval)
  of R_FLOAT:
    result = newJFloat(m.fval)
  of R_INTEGER:
    result = newJInt(m.num)
  of R_ARRAY:
    result = newJArray()
    result.add(newJInt(MAKE_ARRAY.ord))
    var arr = newJArray()
    for x in m.arr:
      arr.add(%x)
    result.add(arr)
  of R_OBJECT:
    result = newJObject()
    for k, v in m.obj.pairs:
      result.fields.add((key: k, val: %v))
  of R_BINARY:
    result = %*{"$reql_type$": "BINARY", "data": m.binary.data}
  of R_TIME:
    var tz =
      if m.time.timezone == 0:
        "+00:00"
      else:
        m.time.format("zzz")
    result = %*{"$reql_type$": "TIME", "epoch_time": m.time.timeInfoToTime.toSeconds(), "timezone": tz}
  of R_TERM:
    result = newJArray()
    result.add(newJInt(m.term.tt.ord))
  else:
    result = newJNull()

template extract*(m: MutableDatum): stmt {.immediate.} =
  case m.kind
  of R_STRING:
    m.str
  of R_BOOLEAN:
    m.bval
  of R_FLOAT:
    m.fval
  of R_INTEGER:
    m.num
  of R_ARRAY:
    m.arr
  of R_OBJECT:
    m.obj
  of R_BINARY:
    m.binary.data
  of R_TIME:
    m.time
  else:
    nil

proc `&`*(s: string): MutableDatum =
  new(result)
  result.kind = R_STRING
  result.str = s

proc `&`*(b: bool): MutableDatum =
  new(result)
  result.kind = R_BOOLEAN
  result.bval = b

proc `&`*(n: float64): MutableDatum =
  new(result)
  result.kind = R_FLOAT
  result.fval = n

proc `&`*(n: int64): MutableDatum =
  new(result)
  result.kind = R_INTEGER
  result.num = n

proc `&`*(a: openArray[MutableDatum]): MutableDatum =
  new(result)
  result.kind = R_ARRAY
  result.arr = @[]
  for x in a:
    result.arr.add(x)

proc `&`*(a: seq[MutableDatum]): MutableDatum =
  new(result)
  result.kind = R_ARRAY
  result.arr = @[]
  for x in a:
    result.arr.add(x)

proc `&`*(o: openArray[tuple[key: string, val: MutableDatum]]): MutableDatum =
  new(result)
  result.kind = R_OBJECT
  result.obj = newTable[string, MutableDatum]()
  for x in o:
    result.obj[x[0]] = x[1]

proc `&`*(o: TableRef[string, MutableDatum]): MutableDatum =
  new(result)
  result.kind = R_OBJECT
  result.obj = o

proc `&`*(b: BinaryData): MutableDatum =
  new(result)
  result.kind = R_BINARY
  result.binary = b

proc `&`*(t: TimeInfo): MutableDatum =
  new(result)
  result.kind = R_TIME
  result.time = t




proc newBinary*(s: string): BinaryData =
  new(result)
  result.data = base64.encode(s)

proc `&`*[T: int|float|string](a: openArray[T]): MutableDatum =
  new(result)
  result.kind = R_ARRAY
  result.arr = @[]
  for x in a:
    result.arr.add(&x)

proc toDatum(x: NimNode): NimNode {.compiletime.} =
  ## Borrowed from JSON module
  ##
  ## See: https://github.com/nim-lang/Nim/blob/devel/lib/pure/json.nim#L690
  case x.kind
  of nnkBracket:
    result = newNimNode(nnkBracket)
    for i in 0 .. <x.len:
      result.add(toDatum(x[i]))

  of nnkTableConstr:
    result = newNimNode(nnkTableConstr)
    for i in 0 .. <x.len:
      assert x[i].kind == nnkExprColonExpr
      result.add(newNimNode(nnkExprColonExpr).add(x[i][0]).add(toDatum(x[i][1])))

  else:
    result = x

  result = prefix(result, "&")

macro `&*`*(x: expr): expr =
  ## Convert an expression to a MutableDatum directly, without having to specify
  ## `%` for every element.
  result = toDatum(x)
