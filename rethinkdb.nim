import asyncdispatch
import rawsockets
import posix
import endians
import strutils

import ql2

const
  BUFFER_SIZE: int = 1024

type

  RethinkClientBase = object of RootObj
    address: string
    port: Port
    auth: string
    sock: TAsyncFD
    queryToken: int32

  RqlDriverError* = object of SystemError
  RqlIOError* = object of IOError
  RqlRuntimeError* = object of SystemError

  RethinkClient* = ref RethinkClientBase


when defined(windows):
  import winlean

  # TODO implemen `sendPacket` proc
else:
  import posix

  proc sendPacket*(r: RethinkClient, data: int): Future[void] =
    var future = newFuture[void]("sendPacket")

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


proc newRethinkClient*(address: string, port = Port(28015), auth = ""): RethinkClient =

  assert address != ""
  assert port != Port(0)

  new(result)
  result.address = address
  result.port = port
  result.auth = auth
  result.sock = newAsyncRawSocket()


proc send*(r: RethinkClient, data: string): Future[void] =
  result = r.sock.send(data)


proc handshake*(r: RethinkClient) {.async.} =
  await r.sendPacket(HandshakeV0_4)
  await  r.sendPacket(r.auth.len)
  if r.auth.len > 0:
    await r.send(r.auth)
  await r.sendPacket(HandshakeJSON)

  var data = await r.sock.recv(1024)
  if not data.startsWith("SUCCESS"):
    raise newException(RqlDriverError, data)

proc connect*(r: RethinkClient) {.async.} =
  await r.sock.connect(r.address, r.port)
  await r.handshake()

proc processResponse(r: RethinkClient) {.async.} =
  while true:
    var data = await r.sock.recv(BUFFER_SIZE)
    if data.len > 0:
      echo "processResponse: ", data


proc run*(r: RethinkClient) {.async.} =
  await r.connect()
  asyncCheck r.processResponse()


when isMainModule:
  asyncCheck newRethinkClient("127.0.0.1").run()
  runForever()
