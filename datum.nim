import json
import ql2


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

proc `&`*(arr: seq[MutableDatum]): MutableDatum =
  new(result)
  result.kind = R_ARRAY
  result.arr = arr

proc `&`*(obj: openArray[tuple[key: string, val: MutableDatum]]): MutableDatum =
  new(result)
  result.kind = R_OBJECT
  result.obj = @[]
  for x in obj:
    result.obj.add(x)  
      
