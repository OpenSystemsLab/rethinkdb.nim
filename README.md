# rethinkdb.nim
RethinkDB driver for Nim

## WIP
Some simple commands are working now

### Manipulating databases
* dbCreate
* dbDrop
* dbList

### Manipulating tables
* tableCreate
* tableDrop
* tableList
* indexCreate
* indexDrop
* indexList
* indexRename
* indexStatus
* indexWait
* changes

### Writing data
* insert
* update
* replace
* delete
* sync

### Selecting data
* db
* table
* get
* getAll
* between
* filter




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
