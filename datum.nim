import json
import tables
import macros
import times
import base64

import ql2
type
  BinaryData* = ref object of RootObj
    data*: string

  MutableDatum* = ref object of RootObj
    case kind*: DatumType
    of R_NULL:
      discard
    of R_BOOLEAN:
      bval*: bool
    of R_NUMBER:
      num*: float64
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

proc `%`*(m: MutableDatum): JsonNode =
  if m.isNil:
    return newJNull()
  case m.kind
  of R_STRING:
    result = newJString(m.str)
  of R_BOOLEAN:
    result = newJBool(m.bval)
  of R_NUMBER:
    result = newJFloat(m.num)
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
    result = %*{"$reql_type$": "TIME", "epoch_time": m.time.timeInfoToTime.toSeconds(), "timezone": m.time.format("zzz")}
  else:
    result = newJNull()

proc `&`*(s: string): MutableDatum =
  new(result)
  result.kind = R_STRING
  result.str = s

proc `&`*(b: bool): MutableDatum =
  new(result)
  result.kind = R_BOOLEAN
  result.bval = b

proc `&`*[T: int|float](n: T): MutableDatum =
  new(result)
  result.kind = R_NUMBER
  result.num = n.float64

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
