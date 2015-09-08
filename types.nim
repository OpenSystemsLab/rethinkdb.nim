import ql2
import tables
import datum

type
  RqlQuery* = object
    args*: seq[RqlQuery]
    optargs*: TableRef[string, RqlQuery]

    case tt*: TermType
    of DATUM:
      value*: MutableDatum
    else:
      discard
