#--------------------
# Manipulating tables
#--------------------

proc tableCreate*[T: RethinkClient|RqlDatabase](r: T, t: string): RqlQuery =
  ## Create a table
  #TODO create options
  ast(r, TABLE_CREATE, t)

proc tableDrop*[T: RethinkClient|RqlDatabase](r: T, t: string): RqlQuery =
  ## Drop a table
  ast(r, TABLE_DROP, t)

#TODO create index

proc indexDrop*(r: RqlTable, t: string): RqlQuery =
  ## Delete a previously created secondary index of this table
  ast(r, INDEX_DROP, t)

proc indexList*(r: RqlTable): RqlQuery =
  ## List all the secondary indexes of this table.
  ast(r, INDEX_LIST)

proc indexRename*(r: RqlTable, oldName, newName: string, overwrite = false): RqlQuery =
  ## Rename an existing secondary index on a table.
  ## If the optional argument overwrite is specified as True,
  ## a previously existing index with the new name will be deleted and the index will be renamed.
  ## If overwrite is False (the default) an error will be raised
  ## if the new index name already exists.
  ast(r, INDEX_RENAME, oldName, newName)
  if overwrite:
    result.addArg(@true)

proc indexStatus*(r: RqlTable, names: varargs[string]): RqlQuery =
  ## Get the status of the specified indexes on this table,
  ## or the status of all indexes on this table if no indexes are specified.
  ast(r, INDEX_STATUS)
  for name in names:
    result.addArg(@name)

proc indexWait*(r: RqlTable, names: varargs[string]): RqlQuery =
  ## Wait for the specified indexes on this table to be ready
  ast(r, INDEX_WAIT)
  for name in names:
    result.addArg(@name)

proc changes*(r: RqlTable): RqlQuery =
  ## Return a changefeed, an infinite stream of objects representing changes to a query
  ast(r, CHANGES)
