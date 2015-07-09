import asyncdispatch
import rethinkdb
import json

proc main() {.async.} =  
  var r = newRethinkClient()
  var response = await r.db("test").table("users").filter({"username": &"admin", "active": &true}).run()
  echo($response)
  response = await r.db("test").table("users").get("4048003589889908736").run
  echo($response)
  #r.disconnect()

when isMainModule:
  asyncCheck main()
  runForever()
