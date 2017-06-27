#--------------------
# Manipulating tables
#--------------------

proc tableCreate*[T: RethinkClient|RqlQuery](r: T, t: string): RqlQuery =
  ## Create a table
  #TODO create options
  when r is RethinkClient:
    newQueryAst(TABLE_CREATE, t)
  else:
    newQueryAst(TABLE_CREATE, r, t)

proc tableDrop*[T: RethinkClient|RqlQuery](r: T, t: string): RqlQuery =
  ## Drop a table
  when r is RethinkClient:
    newQueryAst(TABLE_DROP, t)
  else:
    newQueryAst(TABLE_DROP, r, t)

proc indexCreate*(r: RqlQuery, n: string, f: RqlQuery = nil, multi = false, geo = false): RqlQuery =
  ## Create a new secondary index on a table.
  newQueryAst(INDEX_CREATE, r, n)

  if not isNil(f):
    result.addArg(f)

  if multi:
   result.setOption("multi", multi)

  if geo:
   result.setOption("geo", geo)


proc indexDrop*(r: RqlQuery, n: string): RqlQuery =
  ## Delete a previously created secondary index of this table
  newQueryAst(INDEX_DROP, r, n)

proc indexList*(r: RqlQuery): RqlQuery =
  ## List all the secondary indexes of this table.
  newQueryAst(INDEX_LIST, r)

proc indexRename*(r: RqlQuery, oldName, newName: string, overwrite = false): RqlQuery =
  ## Rename an existing secondary index on a table.
  ## If the optional argument overwrite is specified as True,
  ## a previously existing index with the new name will be deleted and the index will be renamed.
  ## If overwrite is False (the default) an error will be raised
  ## if the new index name already exists.
  newQueryAst(INDEX_RENAME, r, oldName, newName)
  if overwrite:
    result.addArg(newDatum(overwrite))

proc indexStatus*(r: RqlQuery, names: varargs[string]): RqlQuery =
  ## Get the status of the specified indexes on this table,
  ## or the status of all indexes on this table if no indexes are specified.
  newQueryAst(INDEX_STATUS, r)
  for name in names:
    result.addArg(newDatum(name))

proc indexWait*(r: RqlQuery, names: varargs[string]): RqlQuery =
  ## Wait for the specified indexes on this table to be ready
  newQueryAst(INDEX_WAIT, r)
  for name in names:
    result.addArg(newDatum(name))

proc changes*[T](r: T, squash = false, includeStates = false): RqlQuery =
  ## Return a changefeed, an infinite stream of objects representing changes to a query
  newQueryAst(CHANGES, r)
  if squash:
    result.setOption("squash", squash)
  if includeStates:
    result.setOption("include_states", includeStates)
