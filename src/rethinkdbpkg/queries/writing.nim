#--------------------
# Writing data
#--------------------

proc insert*(r: RqlQuery, data: MutableDatum, durability="hard", returnChanges=false, conflict="error"): RqlQuery =
  ## Insert documents into a table. Accepts a single document or an array of documents
  NEW_QUERY(INSERT, r, data)

  if durability != "hard":
    result.setOption("durability", durability)
  if returnChanges:
    result.setOption("return_changes", true)
  if conflict != "error":
    result.setOption("conflict", conflict)

proc insert*(r: RqlQuery, data: openArray[MutableDatum], durability="hard", returnChanges=false, conflict="error"): RqlQuery =
  ## Insert documents into a table. Accepts a single document or an array of documents
  NEW_QUERY(INSERT, r, data)

  if durability != "hard":
    result.setOption("durability", durability)
  if returnChanges:
    result.setOption("return_changes", true)
  if conflict != "error":
    result.setOption("conflict", conflict)

proc update*[T](r: RqlQuery, data: T, durability="hard", returnChanges=false, nonAtomic=false): RqlQuery =
  ## Insert documents into a table. Accepts a single document or an array of documents
  NEW_QUERY(UPDATE, r)
  when data is array:
    result.addArg(makeFunc(&data))
  else:
    result.addArg(data)

  if durability != "hard":
    result.setOption("durability", durability)
  if returnChanges:
    result.setOption("return_changes", true)
  if nonAtomic:
    result.setOption("non_atomic", nonAtomic)

proc replace*[T](r: RqlQuery, data: T, durability="hard", returnChanges=false, nonAtomic=false): RqlQuery =
  ## Replace documents in a table. Accepts a JSON document or a ReQL expression,
  ## and replaces the original document with the new one. The new document must have the same primary key as the original document.
  when data is array:
    NEW_QUERY(REPLACE, r, makeFunc(&data))
  else:
    NEW_QUERY(REPLACE, r, data)

  if durability != "hard":
    result.setOption("durability", durability)
  if returnChanges:
    result.setOption("return_changes", true)
  if nonAtomic:
    result.setOption("non_atomic", nonAtomic)

proc delete*(r: RqlQuery, data: MutableDatum, durability="hard", returnChanges=false): RqlQuery =
  ## Delete one or more documents from a table.
  NEW_QUERY(DELETE, r, data)
  if durability != "hard":
    result.setOption("durability", durability)
  if returnChanges:
    result.setOption("return_changes", true)

proc sync*(r: RqlQuery, data: MutableDatum): RqlQuery =
  ## `sync` ensures that writes on a given table are written to permanent storage
  NEW_QUERY(SYNC, r, data)
