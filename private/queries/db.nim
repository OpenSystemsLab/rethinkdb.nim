#--------------------
# Manipulating databases
#--------------------

proc dbCreate*(r: RethinkClient, db: string): RqlQuery =
  ## Create a table
  NEW_QUERY(DB_CREATE, db)

proc dbDrop*(r: RethinkClient, db: string): RqlQuery =
  ## Drop a database
  NEW_QUERY(DB_DROP, db)

proc dbList*(r: RethinkClient): RqlQuery =
  ## List all database names in the system. The result is a list of strings.
  NEW_QUERY(DB_LIST)
