import macros, json, tables, net, asyncdispatch, asyncnet

import types, ql2, datum

template NEW_QUERY*(t: TermType): untyped =
  result = newQuery(t)

template NEW_QUERY*(t: TermType, a1: untyped): untyped =
  result = newQuery(t)
  result.addArg(a1)

template NEW_QUERY*(t: TermType, a1, a2: untyped): untyped =
  result = newQuery(t)
  result.optargs = newTable[string, RqlQuery]()
  result.addArg(a1)
  result.addArg(a2)

template NEW_QUERY*(t: TermType, a1, a2, a3: untyped): untyped =
  result = newQuery(t)
  result.optargs = newTable[string, RqlQuery]()
  result.addArg(a1)
  result.addArg(a2)
  result.addArg(a3)

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
