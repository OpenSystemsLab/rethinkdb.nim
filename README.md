# RethinkDB driver for Nim

## Installation
```
$ nimble install rethinkdb
```

## Accessing ReQL
### r
Initiate new RethinkDB Client
```nim
import rethinkdb
var r = newRethinkclient([address = "127.0.0.1",] [port = Port(28015),] [auth = "",] [db = ""])
```
### connect
Create a connection to database server, using infomation from RethinkClient
```nim
r.connect()
```
### repl
Set the default connection to make REPL use easier. Allows calling .run() on queries without specifying a connection.
```nim
r.repl()
#or
r.connect().repl()
```
### close
Close an open connetion
```nim
r.close()
```
### reconnect
Close and reopen a connection
```nim
r.reconnect()
```
### use
Change the defalt database on this connection
```nim
r.use(db_name)
```
### run
Run a query on a connection, returning a JsonNode.
```nim
var r = newRethinkclient()
r.connect().repl()
r.table("test").run()
```

## Manipulating databases
* dbCreate
* dbDrop
* dbList

## Manipulating tables
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

## Writing data
* insert
* update
* replace
* delete
* sync

## Selecting data
* db
* table
* get
* getAll
* between
* filter
