import asyncdispatch
import rawsockets
import endians
import strutils
import logging
import parseutils
import struct
import ql2
import utils

const
  BUFFER_SIZE: int = 1024
  HEX = "0123456789abcdef"  
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

  #TODO implemen `sendInt` proc
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

proc debug(a: string) {.inline.} =
  let lookup {.global.} = "0123456789abcdef"
  
  var ret = ""
  for c in a:
    ret &= $(c.ord shr 4)
    ret &= $(lookup[c.ord and 0x0f])
  echo ret

proc send*(r: RethinkClient, data: string): Future[void] =
  result = r.sock.send(data)

proc printHex(s: string) =
  var ret = "printHex: "
  for c in s:
    ret &= "\\x"
    ret &= $(c.ord shr 4)
    ret &= $(HEX[c.ord and 0x0f])
  echo ret
  
proc sendQuery*(r: RethinkClient, query: string): Future[void] =
  L.log(lvlDebug, "Sending query: $#" % [query])
  var future = newFuture[void]("sendQuery")
  proc cb(sock: TAsyncFD): bool {.nimcall.} =
    result = true
    r.queryToken.inc()
    var data = newStruct(">q<i$#s" % $query.len).add(r.queryToken).add(query.len.int32).add(query).pack()
    #printHex(data)   
    discard r.send(data)
    future.complete()
  addWrite(r.sock, cb)
  return future

proc newRethinkClient*(address = "127.0.0.1", port = Port(28015), auth = ""): RethinkClient =
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
  if data[0..6] != "SUCCESS":
    raise newException(RqlDriverError, data)
  L.log(lvlDebug, "Handshake success...")

proc processResponse(r: RethinkClient) {.async.} =
  while true:
    var data = await r.sock.recv(12)
    var header = unpack(">q<i", data)
    var token = header[0].getQuad
    var len = header[1].getInt
    var message = await r.sock.recv(len.int)
    L.log(lvlDebug, "[$#, $#, $#]" % [$token, $len, message])

proc connect*(r: RethinkClient) {.async.} =
  L.log(lvlDebug, "Connecting to server at $#:$#..." % [r.address, $r.port])
  await r.sock.connect(r.address, r.port)
  await r.handshake()
  asyncCheck r.processResponse()
  
