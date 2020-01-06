import ql2, times

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
      obj*: seq[MutableDatumPairs]
    of R_BINARY:
      binary*: BinaryData
    of R_TIME:
      time*: DateTime
    of R_TERM:
      term*: RqlQuery

  MutableDatumPairs* = (string, MutableDatum)
  RqlQueryPairs* = (string, RqlQuery)

  RqlQuery* = ref object of RootObj
    args*: seq[RqlQuery]
    optargs*: seq[RqlQueryPairs]
    tt*: TermType
    value*: MutableDatum
