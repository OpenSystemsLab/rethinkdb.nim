import asyncdispatch
import rawsockets
import endians
import strutils
import logging
import parseutils

import ql2
import utils

const
  BUFFER_SIZE: int = 1024

type

  RethinkClientBase = object of RootObj
    address: string
    port: Port
    auth: string
    sock: TAsyncFD
    queryToken: uint64

  RqlDriverError* = object of SystemError
  RqlIOError* = object of IOError
  RqlRuntimeError* = object of SystemError

  RethinkClient* = ref RethinkClientBase

var
  L = newConsoleLogger()

when defined(windows):
  import winlean

  # TODO implemen `sendInt` proc
else:
  import posix

  proc sendInt*(r: RethinkClient, data: int): Future[void] =
    var future = newFuture[void]("sendInt")

    proc cb(sock: TAsyncFD): bool =
      result = true
      var data = data
      var buf: int32
      littleEndian32(addr buf, addr data)
      let res = sock.SocketHandle.send(addr buf, sizeof(buf), MSG_NOSIGNAL)
      if res < 0:
        result = false
        future.fail(newException(RqlIOError, "Send packet error: " & $res))
      else:
        future.complete()
    addWrite(r.sock, cb)
    return future

  proc sendQueryToken(r: RethinkClient) =
    var buf: int64
    r.queryToken.inc()
    bigEndian64(addr buf, addr r.queryToken)
    discard r.sock.SocketHandle.send(addr buf, sizeof(buf), MSG_NOSIGNAL)


proc send*(r: RethinkClient, data: string): Future[void] =
  result = r.sock.send(data)

proc sendQuery*(r: RethinkClient, query: string): Future[void] =
  L.log(lvlDebug, "Sending query: $#" % [query])
  var future = newFuture[void]("sendQuery")
  proc cb(sock: TAsyncFD): bool =
    result = true

    #r.sendQueryToken()
    #discard r.sendInt(query.len)
    var buf: int64
    r.queryToken.inc()
    bigEndian64(addr buf, addr r.queryToken)
    discard r.sock.SocketHandle.send(addr buf, sizeof(buf), MSG_NOSIGNAL)
    var query = query
    var queryLen = query.len
    var buf1: int32
    littleEndian32(addr buf1, addr queryLen)
    discard r.sock.SocketHandle.send(addr buf1, sizeof(buf1), MSG_NOSIGNAL)
    discard r.sock.SocketHandle.send(addr query, query.len, MSG_NOSIGNAL)

    future.complete()

  addWrite(r.sock, cb)
  return future

proc newRethinkClient*(address: string, port = Port(28015), auth = ""): RethinkClient =

  assert address != ""
  assert port != Port(0)

  new(result)
  result.address = address
  result.port = port
  result.auth = auth
  result.sock = newAsyncRawSocket()
  result.queryToken = 0

proc handshake*(r: RethinkClient) {.async.} =
  L.log(lvlDebug, "Preparing handshake...")
  await r.sendInt(HandshakeV0_4)
  await  r.sendInt(r.auth.len)
  if r.auth.len > 0:
    await r.send(r.auth)
  await r.sendInt(HandshakeJSON)

  var data = await r.sock.recv(BUFFER_SIZE)
  if not data.startsWith("SUCCESS"):
    raise newException(RqlDriverError, data)
  L.log(lvlDebug, "Handshake success...")

proc connect*(r: RethinkClient) {.async.} =
  L.log(lvlDebug, "Connecting to server at $#:$#..." % [r.address, $r.port])
  await r.sock.connect(r.address, r.port)
  await r.handshake()

proc processResponse(r: RethinkClient) {.async.} =
  while true:
    var data = await r.sock.recv(8)
    var token = data.toInt
    data = await r.sock.recv(4)
    var lenLe = data.toInt32
    var len: int
    bigEndian32(addr len, addr lenLe)
    var message = await r.sock.recv(len)
    echo "[$#, $#, $#]" % [$token, $len, message]


proc run*(r: RethinkClient) {.async.} =
  await r.connect()
  asyncCheck r.processResponse()
  await r.sendQuery("foo")
  await r.sendQuery("blah")



when isMainModule:
  asyncCheck newRethinkClient("127.0.0.1").run()
  runForever()
