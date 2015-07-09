import asyncdispatch
import rethinkdb
import json

proc main() {.async.} =  
  var r = newRethinkClient()
  #let response = await r.db("test").table("users").filter({"username": &"admin", "active": &true}).run()
  let response = await r.dbList().run()
  echo($response)
  
  #r.disconnect()

when isMainModule:
  asyncCheck main()
  runForever()
