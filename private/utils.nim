import macros, json, net, asyncdispatch, asyncnet

import types, ql2, datum

template NEW_QUERY*(t: TermType): void =
  result = newQuery(t)

template NEW_QUERY*(t: TermType, a1: typed): void =
  result = newQuery(t).addArg(a1)

template NEW_QUERY*(t: TermType, a1, a2: typed): void =
  result = newQuery(t).addArg(a1).addArg(a2)

template NEW_QUERY*(t: TermType, a1, a2, a3: typed): void =
  result = newQuery(t).addArg(a1).addArg(a2).addArg(a3)

proc newQuery*(tt: TermType): RqlQuery {.inline.} =
  new result
  result.tt = tt

proc newDatum*[T](t: T): RqlQuery =
  when t is RqlQuery:
    result = t
  elif t is MutableDatum:
    result = RqlQuery(tt: DATUM, value: t)
  else:
    result = RqlQuery(tt: DATUM, value: t.toDatum)

proc addArg*[T](r: RqlQuery, t: T): RqlQuery {.discardable.} =
  when t is RqlQuery:
    r.args.add(t)
  else:
    r.args.add(newDatum(t))
  result = r

proc setOption*(r: RqlQuery, k: string, v: RqlQuery) {.noSideEffect, inline.} =
  r.optargs.add((k, v))

proc setOption*[T](r: RqlQuery, k: string, v: T) {.noSideEffect, inline.} =
  r.optargs.add((k, newDatum(v)))

proc readUntil*(s: Socket, delim: char): string =
  result = ""

  var
    c: char
    byteRead = 0

  while s.recv(addr c, 1) == 1:
    if c == delim:
      break

    result.add c
    inc byteRead

proc readUntil*(s: AsyncSocket, delim: char): Future[string] {.async.} =
  result = ""

  var
    c: char
    byteRead = 0
    ret: int

  while true:
    ret = await s.recvInto(addr c, 1)
    if ret != 1 or c == delim:
      break

    result.add c
    inc byteRead
