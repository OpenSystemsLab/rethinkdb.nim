import asyncdispatch
import json

import ../rethinkdb


proc main() {.async.} =  
  var r = newRethinkClient()
  var response = await r.db("test").table("users").filter({"username": &"admin", "active": &true}).run()
  echo($response)
  response = await r.db("test").table("users").get(response[0]["id"].str).run
  echo($response)
  #r.disconnect()

when isMainModule:
  asyncCheck main()
  runForever()
