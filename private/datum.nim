import json, macros, times, base64
import types, ql2

{.checks: off.}

proc toJson*(r: RqlQuery): JsonNode {.thread.}

proc `%`*(m: MutableDatum): JsonNode {.thread.} =
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
    for p in m.obj:
      result.add(p[0], %p[1])
  of R_BINARY:
    result = %*{"$reql_type$": "BINARY", "data": m.binary.string}
  of R_TIME:
    var tz =
      if m.time.timezone == utc():
        "+00:00"
      else:
        m.time.format("zzz")
    result = %*{"$reql_type$": "TIME", "epoch_time": m.time.toTime.toUnix(), "timezone": tz}
  of R_TERM:
    result = newJArray()
    result.add(newJInt(m.term.tt.ord))
    var args = newJArray()
    for arg in m.term.args:
      args.add(arg.toJson)
    result.add(args)
  else:
    result = newJNull()

proc toJson*(r: RqlQuery): JsonNode =
  case r.tt
  of DATUM:
    result = %r.value
  else:
    result = newJArray()
    result.add(newJInt(r.tt.ord))
    var arr = newJArray()
    for x in r.args:
      arr.add(x.toJson)
    result.add(arr)
    if r.optargs.len > 0:
      var obj = newJObject()
      for v in r.optargs:
        obj.add(v[0], v[1].toJson)

      result.add(obj)


template extract*(m: MutableDatum): untyped =
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

proc toDatum*[T](v: T): MutableDatum {.inline.} =
  #debugEcho T.type
  when T is string:
    result = MutableDatum(kind: R_STRING, str: v)
  elif T is bool:
    result = MutableDatum(kind: R_BOOLEAN, bval: v)
  elif T is SomeFloat:
    result = MutableDatum(kind: R_FLOAT, fval: v)
  elif T is SomeInteger:
    result = MutableDatum(kind: R_INTEGER, num: v)
  elif T is array or T is openArray:
    when v[0] is (string, MutableDatum):
      result = MutableDatum(kind: R_OBJECT)
      for x in v:
        result.obj.add((x[0], x[1]))
    else:
      result = MutableDatum(kind: R_ARRAY)
      for x in v:
        result.arr.add(x.toDatum)
  elif T is seq[MutableDatum]:
    result = MutableDatum(kind: R_ARRAY)
    for x in v:
      result.arr.add(x)
  elif T is (string, MutableDatum):
    var tbl = initTable[string, MutableDatum]()
    tbl[v[0]] = toDatum(v[1])
    result = toDatum(tbl)
  elif T is seq[(string, MutableDatum)]:
    result = MutableDatum(kind: R_OBJECT, obj: v)
  elif T is BinaryData:
    result = MutableDatum(kind: R_BINARY, binary: v)
  elif T is DateTime:
    result = MutableDatum(kind: R_TIME, time: v)
  elif T is RqlQuery:
    result = MutableDatum(kind: R_TERM, term: v)
  elif T is MutableDatum:
    result = v
  else:
    result = MutableDatum()

template toBinary*(s: string): BinaryData = BinaryData(base64.encode(s))

proc toDatum*(node: JsonNode): MutableDatum {.inline.} =
  case node.kind
  of JString:
    result = MutableDatum(kind: R_STRING, str: node.str)
  of JInt:
    result = MutableDatum(kind: R_INTEGER, num: node.num)
  of JFloat:
    result = MutableDatum(kind: R_FLOAT, fval: node.fnum)
  of JBool:
    result = MutableDatum(kind: R_BOOLEAN, bval: node.bval)
  of JNull:
    result = MutableDatum(kind: R_NULL)
  of JObject:
    result = MutableDatum(kind: R_OBJECT)
    for key, item in node:
      result.obj.add((key, toDatum(item)))
  of JArray:
    result = MutableDatum(kind: R_ARRAY)
    for item in items(node.elems):
      result.arr.add(toDatum(item))

proc `&`*(t: any): MutableDatum {.compileTime.} = toDatum(t)

proc toDatum(x: NimNode): NimNode {.compiletime.} =
  ## Borrowed from JSON module
  ##
  ## See: https://github.com/nim-lang/Nim/blob/devel/lib/pure/json.nim#L690
  case x.kind
  of nnkBracket:
    result = newNimNode(nnkBracket)
    for i in 0..<x.len:
      result.add(toDatum(x[i]))
  of nnkTableConstr:
    result = newNimNode(nnkTableConstr)
    for i in 0..<x.len:
      assert x[i].kind == nnkExprColonExpr
      result.add(newNimNode(nnkExprColonExpr).add(x[i][0]).add(toDatum(x[i][1])))
  else:
    result = x
  result = newCall(ident("toDatum"), result)
  #result = prefix(result, "&")


macro `&*`*(x: untyped): untyped =
  ## Convert an expression to a MutableDatum directly, without having to specify
  ## `%` for every element.
  result = toDatum(x)
