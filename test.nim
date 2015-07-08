import asyncdispatch

import rethinkdb


proc main() {.async.} =  
  var r = newRethinkClient()
  await r.db("blog").table("pins").run()
    #.filter({"name": newStringDatum("Hello World!")}).run()

when isMainModule:
  asyncCheck main()
  runForever()
