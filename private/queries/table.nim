#--------------------
# Manipulating tables
#--------------------

proc tableCreate*(r: RethinkClient, t: string): RqlQuery =
  ## Create a table
  #TODO create options
  NEW_QUERY(TABLE_CREATE, t)

proc tableCreate*(r: RqlQuery, t: string): RqlQuery =
  ## Create a table
  #TODO create options
  NEW_QUERY(TABLE_CREATE, r, t)

proc tableDrop*(r: RethinkClient, t: string): RqlQuery =
  ## Drop a table
  NEW_QUERY(TABLE_DROP, t)

proc tableDrop*(r: RqlQuery, t: string): RqlQuery =
  ## Drop a table
  NEW_QUERY(TABLE_DROP, r, t)

proc indexCreate*(r: RqlQuery, n: string, f: RqlQuery = nil, multi = false, geo = false): RqlQuery =
  ## Create a new secondary index on a table.
  NEW_QUERY(INDEX_CREATE, r, n)

  if not isNil(f):
    result.addArg(f)

  if multi:
   result.setOption("multi", multi)

  if geo:
   result.setOption("geo", geo)


proc indexDrop*(r: RqlQuery, n: string): RqlQuery =
  ## Delete a previously created secondary index of this table
  NEW_QUERY(INDEX_DROP, r, n)

proc indexList*(r: RqlQuery): RqlQuery =
  ## List all the secondary indexes of this table.
  NEW_QUERY(INDEX_LIST, r)

proc indexRename*(r: RqlQuery, oldName, newName: string, overwrite = false): RqlQuery =
  ## Rename an existing secondary index on a table.
  ## If the optional argument overwrite is specified as True,
  ## a previously existing index with the new name will be deleted and the index will be renamed.
  ## If overwrite is False (the default) an error will be raised
  ## if the new index name already exists.
  NEW_QUERY(INDEX_RENAME, r, oldName, newName)
  if overwrite:
    result.addArg(newDatum(overwrite))

proc indexStatus*(r: RqlQuery, names: varargs[string]): RqlQuery =
  ## Get the status of the specified indexes on this table,
  ## or the status of all indexes on this table if no indexes are specified.
  NEW_QUERY(INDEX_STATUS, r)
  for name in names:
    result.addArg(newDatum(name))

proc indexWait*(r: RqlQuery, names: varargs[string]): RqlQuery =
  ## Wait for the specified indexes on this table to be ready
  NEW_QUERY(INDEX_WAIT, r)
  for name in names:
    result.addArg(newDatum(name))

proc changes*[T](r: T, squash = false, includeStates = false): RqlQuery =
  ## Return a changefeed, an infinite stream of objects representing changes to a query
  NEW_QUERY(CHANGES, r)
  if squash:
    result.setOption("squash", squash)
  if includeStates:
    result.setOption("include_states", includeStates)
