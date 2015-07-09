import asyncdispatch
import rawsockets
import strutils
import logging
import json
import struct

import ql2
import term

const
  BUFFER_SIZE: int = 1024
type
  
  RethinkClientBase = object of RootObj
    address: string
    port: Port
    auth: string
    sock: AsyncFD
    sockConnected: bool
    queryToken: uint64

  RqlDriverError* = object of SystemError
  RqlClientError* = object of SystemError
  RqlCompileError* = object of SystemError
  RqlRuntimeError* = object of SystemError

  RethinkClient* = ref RethinkClientBase

  Response* = ref object of RootObj
    kind*: ResponseType
    token*: uint64
    data*: JsonNode
    backtrace*: JsonNode
    profile*: JsonNode

  Query* = ref object of RootObj
    kind*: QueryType
    term*: Term
    options*: MutableDatum  


var
  L = newConsoleLogger()

proc `$`*(q: Query): string =
  var j = newJArray()
  j.add(newJInt(q.kind.ord))
  j.add(%q.term)
  if not q.options.isNil:
    j.add(%q.options)
  else:
    j.add(newJObject())
  result = $j

proc `$`*(r: Response): string =
  var j = newJArray()
  j.add(newJString($r.kind))
  j.add(r.data)
  #if r.kind != SUCCESS_ATOM:
  #  j.add(r.backtrace)
  #  j.add(r.profile)
  result = $j
proc newResponse(s: string, t: uint64 = 0): Response =
  new(result)
  let json = parseJson(s)
  result.kind = (ResponseType)json["t"].num
  result.token = t
  result.data = json["r"]
  if not json["b"].isNil:
    result.backtrace = json["b"]
  if not json["p"].isNil:
    result.profile = json["p"]  
  
proc nextToken(r: RethinkClient): uint64 =
  r.queryToken.inc()
  result = r.queryToken

proc newRethinkClient*(address = "127.0.0.1", port = Port(28015), auth = ""): RethinkClient =
  assert address != ""
  assert port != Port(0)
  new(result)
  result.address = address
  result.port = port
  result.auth = auth
  result.sock = newAsyncRawSocket()
  result.sockConnected = false
  result.queryToken = 0

proc handshake(r: RethinkClient) {.async.} =
  L.log(lvlDebug, "Preparing handshake...")
  var data: string
  if r.auth.len > 0:
    data = newStruct("<ii$#si" % [$r.auth.len]).add(HandshakeV0_4).add(r.auth.len.int32).add(r.auth).add(HandshakeJSON).pack()
  else:
    data = newStruct("<iii").add(HandshakeV0_4).add(0.int32).add(HandshakeJSON).pack()    
  await r.sock.send(data)
  
  data = await r.sock.recv(BUFFER_SIZE)
  if data[0..6] != "SUCCESS":
    raise newException(RqlDriverError, data)
  L.log(lvlDebug, "Handshake success...")

proc disconnect*(r: RethinkClient) =
  r.sock.closeSocket()
  r.sockConnected = false

proc runQuery(r: RethinkClient, q: Query, token: uint64 = 0) {.async.} =
  L.log(lvlDebug, "Sending query: $#" % [$q])

  if token == 0:
    var token = r.nextToken
  
  let term = $q
  let termLen = term.len.int32
  let data = newStruct(">q<i$#s" % $termLen).add(token).add(termLen).add(term).pack()
  await r.sock.send(data)

proc startQuery(r: RethinkClient, term: Term) {.async.} =
  var q: Query
  new(q)
  q.kind = START
  q.term = term
  #q.options

  await r.runQuery(q)
  
proc continueQuery*(r: RethinkClient, token: uint64 = 0) {.async.} =
  L.log(lvlDebug, "Sending continue query")
  var q: Query
  new(q)
  q.kind = CONTINUE
  await r.runQuery(q, token)
  
proc readResponse*(r: RethinkClient): Future[Response] {.async.} =
  let data = await r.sock.recv(12)
  if data == "":
    r.disconnect()
      
  let header = unpack(">Q<i", data)
  #token = header[0].getUQuad
  #length = header[1].getInt
  let buf = await r.sock.recv(header[1].getInt)
  L.log(lvlDebug, "[$#, $#, $#]" % [$header[0].getUQuad, $header[1].getInt, buf])

  result = newResponse(buf, header[0].getUQuad)

proc isConnected*(r: RethinkClient): bool {.noSideEffect, inline.} =
  return r.sockConnected
  
proc connect*(r: RethinkClient) {.async.} =
  if not r.isConnected:
    L.log(lvlDebug, "Connecting to server at $#:$#..." % [r.address, $r.port])
    await r.sock.connect(r.address, r.port)
    r.sockConnected = true
    await r.handshake()
  
proc reconnect*(r: RethinkClient) {.async.} =
  await r.connect()

