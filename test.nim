import asyncdispatch
import rethinkdb


proc main() {.async.} =  
  var r = newRethinkClient()
  discard await r.db("test").table("users").filter({"username": newStringDatum("admin"), "active": newBoolDatum(true)}).run()
  r.disconnect()

when isMainModule:
  asyncCheck main()
  runForever()
