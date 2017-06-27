import macros, json, tables, net

import types, ql2, datum

macro newQueryAst*(n: varargs[untyped]): untyped =
  result = newNimNode(nnkStmtList)
  # result = new(RqlQuery)
  result.add(
    newAssignment(
      ident("result"),
      newCall("new", ident("RqlQuery"))
    )
  )

  # result.tt = TermType
  result.add(
    newAssignment(
      newDotExpr(ident("result"), ident("tt")),
      newIdentNode($n[0])
    )
  )

  # result.args = @[]
  result.add(
    newAssignment(
      newDotExpr(ident("result"), ident("args")), prefix(newNimNode(nnkBracket), "@")
    )
  )

  # result.optargs = newTable[string, Mutabledatum]()
  var bracket = newNimNode(nnkBracketExpr)
  bracket.add(ident("newTable"))
  bracket.add(ident("string"))
  bracket.add(ident("RqlQuery"))

  result.add(
    newAssignment(
      newDotExpr(ident("result"), ident("optargs")),
      newCall(bracket)
    )
  )

  if n.len > 1:
    for i in 1..<n.len:
      result.add(newCall("addArg", ident("result"), newIdentNode($n[i])))

proc newQuery*(tt: TermType): RqlQuery {.inline.} =
  new(result)
  result.tt = tt
  result.args = @[]
  result.optargs = newTable[string, RqlQuery]()

proc newDatum*(t: MutableDatum): RqlQuery =
  new(result)
  result.tt = DATUM
  result.value = t

proc newDatum*[T](t: T): RqlQuery =
  when t is RqlQuery:
    result = t
  else:
    newDatum(&t)

proc `@`*[T](t: T): RqlQUery =
  newDatum(t)

proc addArg*[T](r: RqlQuery, t: T) =
  when t is RqlQuery:
    r.args.add(t)
  else:
    r.args.add(newDatum(t))

proc setOption*(r: RqlQuery, k: string, v: RqlQuery) {.noSideEffect, inline.} =
  r.optargs[k] = v

proc setOption*[T](r: RqlQuery, k: string, v: T) {.noSideEffect, inline.} =
  r.optargs[k] = newDatum(v)

proc readUntil*(s: Socket, delim: char, bufferSize = 12): string =
  result = newString(bufferSize)
  var
    c: char
    byteRead = 0
  while s.recv(addr c, 1) == 1:
    if c == delim:
      break

    if byteRead >= result.len:
      setLen(result, result.len + bufferSize)

    result[byteRead] = c

    inc(byteRead)
