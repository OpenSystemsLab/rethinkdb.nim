import asyncdispatch
import rawsockets
import strutils
import logging
import json
import struct
import tables

import ql2
import types
import utils
import datum

const
  BUFFER_SIZE: int = 1024

type
  RethinkClient* = ref object of RootObj
    address: string
    port: Port
    auth: string
    options: TableRef[string, RqlQuery]
    sock: AsyncFD
    sockConnected: bool
    queryToken: uint64

  RqlDriverError* = object of SystemError
  RqlClientError* = object of SystemError
  RqlCompileError* = object of SystemError
  RqlRuntimeError* = object of SystemError

  Response* = ref object of RootObj
    kind*: ResponseType
    token*: uint64
    data*: JsonNode
    backtrace*: JsonNode
    profile*: JsonNode

  Query* = ref object of RootObj
    kind*: QueryType
    term*: RqlQuery
    options*: TableRef[string, RqlQuery]

var
  L = newConsoleLogger()

proc `$`*(q: Query): string =
  var j = newJArray()
  j.add(newJInt(q.kind.ord))

  if q.kind == START:
    j.add(q.term.toJson)
    var opts = newJObject()
    for k, v in q.options.pairs():
        opts.add(k, v.toJson)
    j.add(opts)
  result = $j

proc `$`*(r: Response): string =
  var j = newJArray()
  j.add(newJString($r.kind))
  j.add(r.data)
  #TODO handle backtrace
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

proc addOption*(r: RethinkClient, k: string, v: RqlQuery) =
  ## Set a global option
  r.options[k] = v

proc use*(r: RethinkClient, s: string) =
  ## Change the default database on this connection.
  var term: RqlQuery
  new(term)
  term.tt = DB
  term.args = @[newDatum(s)]
  r.addOption("db", term)

proc newRethinkClient*(address = "127.0.0.1", port = Port(28015), auth = "", db = ""): RethinkClient =
  ## Init new client instance
  assert address != ""
  assert port != Port(0)
  new(result)
  result.address = address
  result.port = port
  result.auth = auth
  result.options = newTable[string, RqlQuery]()
  result.sock = newAsyncRawSocket()
  result.sockConnected = false
  result.queryToken = 0

  if not db.isNil and db != "":
    result.use(db)

proc handshake(r: RethinkClient) {.async.} =
  L.log(lvlDebug, "Preparing handshake...")
  var data: string
  if r.auth.len > 0:
    data = pack("<ii$#si" % [$r.auth.len], HandshakeV0_4, r.auth.len, r.auth, HandshakeJSON)
  else:
    data = pack("<iii", HandshakeV0_4, 0, HandshakeJSON)
  await r.sock.send(data)

  data = await r.sock.recv(BUFFER_SIZE)
  if data[0..6] != "SUCCESS":
    raise newException(RqlDriverError, data)
  L.log(lvlDebug, "Handshake success...")

proc close*(r: RethinkClient) =
  ## Close an open connection
  r.sock.closeSocket()
  r.sockConnected = false
  L.log(lvlDebug, "Disconnected from server...")

proc runQuery(r: RethinkClient, q: Query, token: uint64 = 0) {.async.} =
  q.options = r.options

  L.log(lvlDebug, "Sending query: $#" % [$q])

  var token = token
  if token == 0:
    token = r.nextToken

  let term = $q
  let termLen = term.len.int32
  let data = pack(">q<i$#s" % $termLen, token, termLen, term)
  await r.sock.send(data)

proc startQuery*(r: RethinkClient, t: RqlQuery) {.async.} =
  ## Send START query
  var q: Query
  new(q)
  q.kind = START
  q.term = t
  await r.runQuery(q)

proc continueQuery*(r: RethinkClient, token: uint64 = 0) {.async.} =
  ## Send CONTINUE query
  L.log(lvlDebug, "Sending continue query")
  var q: Query
  new(q)
  q.kind = CONTINUE
  await r.runQuery(q, token)

proc readResponse*(r: RethinkClient): Future[Response] {.async.} =
  let data = await r.sock.recv(12)
  if data == "":
    r.close()

  let header = unpack(">Q<i", data)
  let token = header[0].getUQuad
  let length = header[1].getInt
  let buf = await r.sock.recv(length)
  L.log(lvlDebug, "Response: [$#, $#, $#]" % [$token, $length, buf])

  result = newResponse(buf, token)

proc isConnected*(r: RethinkClient): bool {.noSideEffect, inline.} =
  r.sockConnected

proc connect*(r: RethinkClient) {.async.} =
  ## Create a new connection to the database server
  if not r.isConnected:
    L.log(lvlDebug, "Connecting to server at $#:$#..." % [r.address, $r.port])
    await r.sock.connect(r.address, r.port)
    r.sockConnected = true
    await r.handshake()

proc reconnect*(r: RethinkClient) {.async.} =
  ## Close and reopen a connection
  r.close()
  await r.connect()
