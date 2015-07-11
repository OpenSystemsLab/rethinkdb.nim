import json
import ql2
import macros

type
  MutableDatum* = ref object of RootObj
    case kind*: DatumType
    of R_STR:
      str*: string
    of R_BOOL:
      bval*: bool
    of R_NUM:
      num*: int
    of R_ARRAY:
      arr*: seq[MutableDatum]
    of R_OBJECT:
      obj*: seq[tuple[key: string, val: MutableDatum]]  
    else:
      discard

proc `%`*(m: MutableDatum): JsonNode =
  if m.isNil:
    return newJNull()
  case m.kind
  of R_STR:
    result = newJString(m.str)
  of R_BOOL:
    result = newJBool(m.bval)
  of R_NUM:
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
    for x in m.obj:
      result.fields.add((key: x.key, val: %x.val))
  else:
    result = newJNull()

proc `&`*(s: string): MutableDatum =
  new(result)
  result.kind = R_STR
  result.str = s

proc `&`*(b: bool): MutableDatum =
  new(result)
  result.kind = R_BOOL
  result.bval = b

proc `&`*(n: int): MutableDatum =
  new(result)
  result.kind = R_NUM
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
  result.obj = @[]
  for x in o:
    result.obj.add(x)  
      
proc toMutableDatum(x: NimNode): NimNode {.compiletime.} =
  ## Borrowed from JSON module
  ##
  ## See: https://github.com/nim-lang/Nim/blob/devel/lib/pure/json.nim#L690
  case x.kind
  of nnkBracket:
    result = newNimNode(nnkBracket)
    for i in 0 .. <x.len:
      result.add(toMutableDatum(x[i]))

  of nnkTableConstr:
    result = newNimNode(nnkTableConstr)
    for i in 0 .. <x.len:
      assert x[i].kind == nnkExprColonExpr
      result.add(newNimNode(nnkExprColonExpr).add(x[i][0]).add(toMutableDatum(x[i][1])))

  else:
    result = x

  result = prefix(result, "&")

macro `&*`*(x: expr): expr =
  ## Convert an expression to a MutableDatum directly, without having to specify
  ## `%` for every element.
  result = toMutableDatum(x)
