import asyncdispatch
import rethinkdb


proc main() {.async.} =  
  var r = newRethinkClient()
  #discard await r.db("test").table("users").filter({"username": &"admin", "active": nil}).run()
  discard await r.dbList().run()
  #r.disconnect()

when isMainModule:
  asyncCheck main()
  runForever()
