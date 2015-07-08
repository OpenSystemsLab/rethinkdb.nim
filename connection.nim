import asyncdispatch
import asyncnet
import rawsockets
import strutils
import logging
import struct
import ql2

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
  RqlIOError* = object of IOError
  RqlRuntimeError* = object of SystemError

  RethinkClient* = ref RethinkClientBase

var
  L = newConsoleLogger()

proc sendQuery*(r: RethinkClient, query: string) {.async.} =
  L.log(lvlDebug, "Sending query: $#" % [query])

  r.queryToken.inc()
  let data = newStruct(">q<i$#s" % $query.len).add(r.queryToken).add(query.len.int32).add(query).pack()
  await r.sock.send(data)

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

proc readResponse(r: RethinkClient) {.async.} =
  var data: string
  #var token: uint64
  var length: int
  var message: string
  while true:
    data = await r.sock.recv(12)
    let header = unpack(">Q<I", data)
    #token = header[0].getUQuad
    length = header[1].getUInt.int
    message = await r.sock.recv(length)
    L.log(lvlDebug, "[$#, $#, $#]" % [$header[0].getUQuad, $length, message])

proc isConnected*(r: RethinkClient): bool {.noSideEffect, inline.} =
  return r.sockConnected
  
proc connect*(r: RethinkClient) {.async.} =
  if not r.isConnected:
    L.log(lvlDebug, "Connecting to server at $#:$#..." % [r.address, $r.port])
    await r.sock.connect(r.address, r.port)
    r.sockConnected = true
    await r.handshake()
    asyncCheck r.readResponse()
  
proc reconnect*(r: RethinkClient) {.async.} =
  await r.connect()

proc disconnect*(r: RethinkClient) =
  r.sock.closeSocket()
  r.sockConnected = false
