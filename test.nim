import asyncdispatch

import rethinkdb


proc main() {.async.} =  
  var r = newRethinkClient()
  await r.db("test").table("posts").run()
    #.filter({"name": newStringDatum("Hello World!")}).run()

when isMainModule:
  asyncCheck main()
  runForever()
