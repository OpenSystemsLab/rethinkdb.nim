#--------------------
# Writing data
#--------------------

proc insert*(r: RqlTable, data: openArray[MutableDatum], durability="hard", returnChanges=false, conflict="error"): RqlQuery =
  ## Insert documents into a table. Accepts a single document or an array of documents
  ast(r, INSERT, data)
  result.setOptions(&*{"durability": durability, "return_changes": returnChanges, "conflict": conflict})

proc update*(r: RqlQuery, data: MutableDatum, durability="hard", returnChanges=false, nonAtomic=false): RqlQuery =
  ## Insert documents into a table. Accepts a single document or an array of documents
  ast(r, UPDATE, data)
  result.setOptions(&*{"durability": durability, "return_changes": returnChanges, "non_atomic": nonAtomic})

proc replace*(r: RqlQuery, data: MutableDatum, durability="hard", returnChanges=false, nonAtomic=false): RqlQuery =
  ## Replace documents in a table. Accepts a JSON document or a ReQL expression,
  ## and replaces the original document with the new one. The new document must have the same primary key as the original document.
  ast(r, REPLACE, data)
  result.setOptions(&*{"durability": durability, "return_changes": returnChanges, "non_atomic": nonAtomic})

proc delete*(r: RqlQuery, data: MutableDatum, durability="hard", returnChanges=false): RqlQuery =
  ## Delete one or more documents from a table.
  ast(r, DELETE, data)
  result.setOptions(&*{"durability": durability, "return_changes": returnChanges})

proc sync*(r: RqlQuery, data: MutableDatum): RqlQuery =
  ## `sync` ensures that writes on a given table are written to permanent storage
  ast(r, SYNC, data)
