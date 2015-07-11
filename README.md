# rethinkdb.nim
RethinkDB driver for Nim

## WIP
Some simple commands are working now

#### Manipulating databases
* dbCreate
* dbDrop
* dbList

#### Manipulating tables
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

#### Writing data
* insert
* update
* replace
* delete
* sync

#### Selecting data
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

var r = newRethinkClient()
r.use("test")
discard waitFor r.table("users").filter(&*{"active": true}).run()
r.disconnect()
```
