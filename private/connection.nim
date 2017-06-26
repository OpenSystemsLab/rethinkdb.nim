import nativesockets, strutils, logging, json, struct, tables

when not compileOption("threads"):
  import asyncdispatch
else:
  import net


import ql2, types, utils, datum

when not compileOption("threads"):
  const
    BUFFER_SIZE = 512
  type
    RethinkClient* = ref object of RootObj
      address: string
      port: Port
      auth: string
      options: TableRef[string, MutableDatum]
      sock: AsyncFD
      sockConnected: bool
      queryToken: uint64
else:
  type
    RethinkClient* = ref object of RootObj
      address: string
      port: Port
      auth: string
      options: TableRef[string, MutableDatum]
      sock: Socket
      sockConnected: bool
      queryToken: uint64

type
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
    options*: TableRef[string, MutableDatum]
when defined(debug):
  var L {.threadvar.}: ConsoleLogger
  L = newConsoleLogger()

proc `$`*(q: Query): string {.thread.} =
  var j = newJArray()
  j.add(newJInt(q.kind.ord))

  if q.kind == START:
    j.add(q.term.toJson)
    var opts = newJObject()
    for k, v in q.options.pairs():
        opts.add(k, %v)
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
  if json.hasKey("b"):
    result.backtrace = json["b"]
  if json.hasKey("p"):
    result.profile = json["p"]

proc nextToken(r: RethinkClient): uint64 =
  r.queryToken.inc()
  result = r.queryToken

proc addOption*(r: RethinkClient, k: string, v: MutableDatum) =
  ## Set a global option
  r.options[k] = v

proc use*(r: RethinkClient, s: string) =
  ## Change the default database on this connection.
  var term: RqlQuery
  new(term)
  term.tt = DB
  term.args = @[newDatum(s)]
  r.addOption("db", &term)

proc newRethinkClient*(address = "127.0.0.1", port = Port(28015), auth = "", db = ""): RethinkClient =
  ## Init new client instance
  assert address != ""
  assert port != Port(0)
  new(result)
  result.address = address
  result.port = port
  result.auth = auth
  result.options = newTable[string, MutableDatum]()
  when not compileOption("threads"):
    result.sock = newAsyncNativeSocket()
  else:
    result.sock = newSocket()
  result.sockConnected = false
  result.queryToken = 0

  if not db.isNil and db != "":
    result.use(db)
when not compileOption("threads"):
  proc handshake(r: RethinkClient) {.async.} =
    when defined(debug):
      L.log(lvlDebug, "Preparing handshake...")
    var data: string
    if r.auth.len > 0:
      data = pack("<ii$#si" % [$r.auth.len], HandshakeV0_4, r.auth.len.int32, r.auth, HandshakeJSON)
    else:
      data = pack("<iii", HandshakeV0_4, 0.int32, HandshakeJSON)
    await r.sock.send(data)

    data = await r.sock.recv(BUFFER_SIZE)
    if data[0..6] != "SUCCESS":
      raise newException(RqlDriverError, data)
    when defined(debug):
      L.log(lvlDebug, "Handshake success...")
else:
  proc handshake(r: RethinkClient) =
    when defined(debug):
      L.log(lvlDebug, "Preparing handshake...")
    var data: string
    if r.auth.len > 0:
      data = pack("<ii$#si" % [$r.auth.len], HandshakeV0_4, r.auth.len.int32, r.auth, HandshakeJSON)
    else:
      data = pack("<iii", HandshakeV0_4, 0.int32, HandshakeJSON)
    r.sock.send(data)

    var buf = r.sock.readUntil('\0')

    if buf[0..6] != "SUCCESS":
      raise newException(RqlDriverError, buf)
    when defined(debug):
      L.log(lvlDebug, "Handshake success...")


proc handshake1_0(r: RethinkClient) =
    when defined(debug):
      L.log(lvlDebug, "Preparing handshake...")
    var data = pack("<i", HandshakeV1_0)
    discard r.sock.send(data)

    let buf = r.sock.readUntil('\0')
    if buf[0..4] == "ERROR":
      raise newException(RqlDriverError, buf)
    try:
      let result = parseJson(buf & "AA")
      if not result.hasKey("success") or result["success"].bval != true:
        raise newException(RqlDriverError, "Handshake failed with error: " & buf)
    except JsonParsingError:
      raise newException(RqlDriverError, "Can not parse response from server: " & buf)

    when defined(debug):
      L.log(lvlDebug, "Handshake success...")

proc close*(r: RethinkClient) =
  ## Close an open connection
  when not compileOption("threads"):
    r.sock.closeSocket()
  else:
    r.sock.close()
  r.sockConnected = false
  when defined(debug):
    L.log(lvlDebug, "Disconnected from server...")

proc isConnected*(r: RethinkClient): bool {.noSideEffect, inline.} =
  r.sockConnected

when not compileOption("threads"):
  proc runQuery(r: RethinkClient, q: Query, token: uint64 = 0) {.async.} =
    when defined(debug):
      L.log(lvlDebug, "Sending query: $#" % [$q])
    var token = token
    if token == 0:
      token = r.nextToken
    let term = $q
    let termLen = term.len.int32
    let data = pack(">q<i$#s" % $termLen, token, termLen, term)
    await r.sock.send(data)

  proc startQuery*(r: RethinkClient, t: RqlQuery, options: TableRef[string, MutableDatum] = nil) {.async.} =
    ## Send START query
    var q: Query
    new(q)
    q.kind = START
    q.term = t
    q.options = newTable[string, MutableDatum]()

    if not r.options.isNil and r.options.len > 0:
      for k, v in r.options.pairs():
        q.options.add(k, v)
    if not options.isNil:
      for k, v in options.pairs():
        q.options.add(k, v)

    await r.runQuery(q)

  proc continueQuery*(r: RethinkClient, token: uint64 = 0) {.async.} =
    ## Send CONTINUE query
    when defined(debug):
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
    when defined(debug):
      L.log(lvlDebug, "Response: [$#, $#, $#]" % [$token, $length, buf])

    result = newResponse(buf, token)

  proc connect*(r: RethinkClient) {.async.} =
    ## Create a new connection to the database server
    if not r.isConnected:
      when defined(debug):
        L.log(lvlDebug, "Connecting to server at $#:$#..." % [r.address, $r.port])
      await r.sock.connect(r.address, r.port)
      r.sockConnected = true
      await r.handshake()

  proc reconnect*(r: RethinkClient) {.async.} =
    ## Close and reopen a connection
    r.close()
    await r.connect()

else:
  proc runQuery(r: RethinkClient, q: Query, token: uint64 = 0): int {.thread.} =
    when defined(debug):
      L.log(lvlDebug, "Sending query: $#" % [$q])
    var token = token
    if token == 0:
      token = r.nextToken
    let term = $q
    let termLen = term.len.int32
    var data = pack(">q<i$#s" % $termLen, token, termLen, term)
    r.sock.send(data)

  proc startQuery*(r: RethinkClient, t: RqlQuery, options: TableRef[string, MutableDatum] = nil) =
    ## Send START query
    var q: Query
    new(q)
    q.kind = START
    q.term = t
    q.options = newTable[string, MutableDatum]()

    if not r.options.isNil and r.options.len > 0:
      for k, v in r.options.pairs():
        q.options.add(k, v)
    if not options.isNil:
      for k, v in options.pairs():
        q.options.add(k, v)

    discard r.runQuery(q)

  proc continueQuery*(r: RethinkClient, token: uint64 = 0) =
    ## Send CONTINUE query
    when defined(debug):
      L.log(lvlDebug, "Sending continue query")
    var q: Query
    new(q)
    q.kind = CONTINUE
    discard r.runQuery(q, token)

  proc readResponse*(r: RethinkClient): Response  =
    var data = newString(12)
    var ret = r.sock.recv(data, 12)
    if ret <= 0:
      raise newException(RqlDriverError, "Unable to read packet header")

    let header = unpack(">Q<i", data)
    let token = header[0].getUQuad
    let length = header[1].getInt
    var buf = ""
    ret = r.sock.recv(buf, length)
    if ret <= 0:
      raise newException(RqlDriverError, "Unable to read packet body")
    when defined(debug):
      L.log(lvlDebug, "Response: [$#, $#, $#]" % [$token, $length, buf])

    newResponse(buf, token)

  proc connect*(r: RethinkClient) =
    ## Create a new connection to the database server
    if not r.isConnected:
      when defined(debug):
        L.log(lvlDebug, "Connecting to server at $#:$#..." % [r.address, $r.port])
      r.sock.connect(r.address, r.port)
      r.sockConnected = true
      r.handshake1_0()

  proc reconnect*(r: RethinkClient) =
    ## Close and reopen a connection
    r.close()
    r.connect()
