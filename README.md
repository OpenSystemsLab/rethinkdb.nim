# rethinkdb.nim
RethinkDB driver for Nim

## WIP
Usage:
------
```nim
import asyncdispatch
import rethinkdb


proc main() {.async.} =  
  var r = newRethinkClient()
  discard await r.db("test").table("users").filter({"username": &"admin", "active": true}).run()
  r.disconnect()

when isMainModule:
  asyncCheck main()
  runForever()
```
