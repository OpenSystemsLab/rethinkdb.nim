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
    else:
      discard


proc `%`*(m: MutableDatum): JsonNode =
  case m.kind
  of R_STR:
    result = newJString(m.str)
  of R_BOOL:
    result = newJBool(m.bval)
  of R_NUM:
    result = newJInt(m.num)
  else:
    discard

proc newStringDatum*(s: string): MutableDatum =
  new(result)
  result.kind = R_STR
  result.str = s

proc newBoolDatum*(b: bool): MutableDatum =
  new(result)
  result.kind = R_BOOL
  result.bval = b

proc newNumDatum*(n: int): MutableDatum =
  new(result)
  result.kind = R_NUM
  result.num = n

#proc newMutableDatum(k: DatumType, s: string): MutableDatum =
#  new(result)
#  result.kind = k
#  result.str = s

