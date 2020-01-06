import asyncnet, strutils, logging, json, struct
import scram/client

when not compileOption("threads"):
  import asyncdispatch
else:
  import net

import ql2, types, utils, datum

const
  HANDSHAKE_FIRST_MESSAGE = "{\"protocol_version\": 0,\"authentication_method\": \"SCRAM-SHA-256\",\"authentication\": \"$#\"}\x0"
  HANDSHAKE_FINAL_MESSAGE = "{\"authentication\": \"$#\"}\x0"

when not compileOption("threads"):
  const
    BUFFER_SIZE = 512
  type
    RethinkClient* = ref object of RootObj
      address: string
      port: Port
      username: string
      password: string
      options: TableRef[string, MutableDatum]
      sock: AsyncSocket
      sockConnected: bool
      queryToken: uint64
else:
  type
    RethinkClient* = ref object of RootObj
      address: string
      port: Port
      username: string
      password: string
      options: seq[MutableDatumPairs]
      sock: Socket
      sockConnected: bool
      queryToken: uint64

type
  RqlAuthError* = object of Exception
  RqlDriverError* = object of Exception
  RqlClientError* = object of Exception
  RqlCompileError* = object of Exception
  RqlRuntimeError* = object of Exception

  Response* = ref object of RootObj
    kind*: ResponseType
    token*: uint64
    data*: JsonNode
    backtrace*: JsonNode
    profile*: JsonNode

  Query* = ref object of RootObj
    kind*: QueryType
    term*: RqlQuery
    options*: seq[MutableDatumPairs]
when defined(debug):
  var L {.threadvar.}: ConsoleLogger
  L = newConsoleLogger()

proc `$`*(q: Query): string {.thread.} =
  var j = newJArray()
  j.add(newJInt(q.kind.ord))

  if q.kind == START:
    j.add(q.term.toJson)
    var opts = newJObject()
    for p in q.options:
        opts.add(p[0], %p[1])
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
  result = new(Response)
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
  r.options.add((k, v))

proc use*(r: RethinkClient, s: string) =
  ## Change the default database on this connection.
  var term: RqlQuery
  new(term)
  term.tt = DB
  term.args = @[newDatum(s)]
  r.addOption("db", term.toDatum)

proc newRethinkClient*(address = "127.0.0.1", port = Port(28015), db: string = ""): RethinkClient =
  ## Init new client instance
  assert address != ""
  result = new(RethinkClient)
  result.address = address
  result.port = port
  when not compileOption("threads"):
    result.sock = newAsyncSocket()
  else:
    result.sock = newSocket()
  result.sockConnected = false
  result.queryToken = 0

  if db != "":
    result.use(db)
when not compileOption("threads"):
  proc handshake(r: RethinkClient) {.async.} =
    when defined(debug):
      L.log(lvlDebug, "Preparing handshake...")
    var data = pack("<i", HandshakeV1_0)
    await r.sock.send(data)
    data = await r.sock.readUntil('\0')
    if data[0] != '{':
      raise newException(RqlDriverError, data)
    when defined(debug):
      L.log(lvlDebug, "Server response: ", data)

    let
      scramClient = newScramClient[SHA256Digest]()
      firstMessage = scramClient.prepareFirstMessage(r.username)

    data = HANDSHAKE_FIRST_MESSAGE % firstMessage
    when defined(debug):
      L.log(lvlDebug, "Sending first message: ", data)

    await r.sock.send(data)
    data = await r.sock.readUntil('\0')
    when defined(debug):
      L.log(lvlDebug, "Server response: ", data)
    var response = parseJson(data)
    if not response.hasKey("success") or not response["success"].bval:
      raise newException(RqlAuthError, "Error code " & $response["error_code"].num & ": " & response["error"].str)

    data = HANDSHAKE_FINAL_MESSAGE % scramClient.prepareFinalMessage(r.password, response["authentication"].str)
    when defined(debug):
      L.log(lvlDebug, "Sending final message: ", data)

    await r.sock.send(data)
    data = await r.sock.readUntil('\0')
    when defined(debug):
      L.log(lvlDebug, "Server response: ", data)
    response = parseJson(data)
    if not response.hasKey("success") or not response["success"].bval:
      raise newException(RqlAuthError, "Error code " & $response["error_code"].num & ": " & response["error"].str)

    if not scramClient.verifyServerFinalMessage(response["authentication"].str):
      raise newException(RqlAuthError, "Verification of server final message failed")

    when defined(debug):
      L.log(lvlDebug, "Handshake success...")
else:
  proc handshake(r: RethinkClient) =
    when defined(debug):
      L.log(lvlDebug, "Preparing handshake...")
    var data = pack("<i", HandshakeV1_0)
    r.sock.send(data)
    data = r.sock.readUntil('\0')
    if data[0] != '{':
      raise newException(RqlDriverError, data)
    when defined(debug):
      L.log(lvlDebug, "Server response: ", data)

    let
      scramClient = newScramClient[SHA256Digest]()
      firstMessage = scramClient.prepareFirstMessage(r.username)

    data = HANDSHAKE_FIRST_MESSAGE % firstMessage
    when defined(debug):
      L.log(lvlDebug, "Sending first message: ", data)

    r.sock.send(data)
    data = r.sock.readUntil('\0')
    when defined(debug):
      L.log(lvlDebug, "Server response: ", data)
    var response = parseJson(data)
    if not response.hasKey("success") or not response["success"].bval:
      raise newException(RqlAuthError, "Error code " & $response["error_code"].num & ": " & response["error"].str)

    data = HANDSHAKE_FINAL_MESSAGE % scramClient.prepareFinalMessage(r.password, response["authentication"].str)
    when defined(debug):
      L.log(lvlDebug, "Sending final message: ", data)

    r.sock.send(data)
    data = r.sock.readUntil('\0')
    when defined(debug):
      L.log(lvlDebug, "Server response: ", data)
    when defined(verbose):
      echo "<<< ", data
    response = parseJson(data)
    if not response.hasKey("success") or not response["success"].bval:
      raise newException(RqlAuthError, "Error code " & $response["error_code"].num & ": " & response["error"].str)

    if not scramClient.verifyServerFinalMessage(response["authentication"].str):
      raise newException(RqlAuthError, "Verification of server final message failed")

    when defined(debug):
      L.log(lvlDebug, "Handshake success...")
proc close*(r: RethinkClient) =
  ## Close an open connection
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
    var q = new(Query)
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
    var q = new(Query)
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

  proc connect*(r: RethinkClient, username = "admin", password: string = ""): Future[void] {.async.} =
    ## Create a new connection to the database server
    if not r.isConnected:
      if r.username != username:
        r.username = username
        if not  password.isNilOrEmpty and r.password != password:
          r.password = password
      when defined(debug):
        L.log(lvlDebug, "Connecting to server at $#:$#..." % [r.address, $r.port.int])
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

  proc startQuery*(r: RethinkClient, t: RqlQuery, options: seq[MutableDatumPairs]) =
    ## Send START query
    var q = new(Query)
    q.kind = START
    q.term = t

    if r.options.len > 0:
      for p in r.options:
        q.options.add(p)
    if options.len > 0:
      for p in options:
        q.options.add(p)
    when defined(verbose):
      echo ">>> ", q
    discard r.runQuery(q)

  proc continueQuery*(r: RethinkClient, token: uint64 = 0) =
    ## Send CONTINUE query
    when defined(debug):
      L.log(lvlDebug, "Sending continue query")
    var q = new(Query)
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
    when defined(verbose):
      echo "<<< ", buf
    newResponse(buf, token)

  proc connect*(r: RethinkClient, username = "admin", password: string = "") =
    ## Create a new connection to the database server
    if not r.isConnected:
      if r.username != username:
        r.username = username
      if not  password.isNilOrEmpty and r.password != password:
        r.password = password
      when defined(debug):
        L.log(lvlDebug, "Connecting to server at $#:$#..." % [r.address, $r.port])
      r.sock.connect(r.address, r.port)
      r.sockConnected = true
      r.handshake()

  proc reconnect*(r: RethinkClient) =
    ## Close and reopen a connection
    r.close()
    r.connect()
