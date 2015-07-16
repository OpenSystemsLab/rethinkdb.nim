#--------------------
# Manipulating databases
#--------------------

proc dbCreate*(r: RethinkClient, db: string): RqlQuery =
  ## Create a table
  ast(r, DB_CREATE, db)

proc dbDrop*(r: RethinkClient, db: string): RqlQuery =
  ## Drop a database
  ast(r, DB_DROP, db)

proc dbList*(r: RethinkClient): RqlQuery =
  ## List all database names in the system. The result is a list of strings.
  ast(r, DB_LIST)
