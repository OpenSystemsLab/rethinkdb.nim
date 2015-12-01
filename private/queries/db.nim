#--------------------
# Manipulating databases
#--------------------

proc dbCreate*(r: RethinkClient, db: string): RqlQuery =
  ## Create a table
  newQueryAst(DB_CREATE, db)

proc dbDrop*(r: RethinkClient, db: string): RqlQuery =
  ## Drop a database
  newQueryAst(DB_DROP, db)

proc dbList*(r: RethinkClient): RqlQuery =
  ## List all database names in the system. The result is a list of strings.
  newQueryAst(DB_LIST)
