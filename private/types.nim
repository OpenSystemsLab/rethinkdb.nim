import ql2
import tables
import datum
import times

type
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

  RqlQuery* = ref object of RootObj
    args*: seq[RqlQuery]
    optargs*: TableRef[string, RqlQuery]

    case tt*: TermType
    of DATUM:
      value*: MutableDatum
    else:
      discard
