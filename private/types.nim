import ql2, tables, times

type
  BinaryData* {.borrow.} = distinct string

  MutableDatum* = object
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
      obj*: Table[string, MutableDatum]
    of R_BINARY:
      binary*: BinaryData
    of R_TIME:
      time*: DateTime
    of R_TERM:
      term*: RqlQuery

  RqlQuery* = ref object of RootObj
    args*: seq[RqlQuery]
    optargs*: Table[string, RqlQuery]
    tt*: TermType
    value*: MutableDatum
