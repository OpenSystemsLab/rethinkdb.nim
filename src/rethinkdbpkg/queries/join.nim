#--------------------
# Joins
#--------------------

proc innerJoin*[T, U](r, o: RqlQuery, f: proc(x, y: T): U): RqlQuery =
  ## Returns an inner join of two sequences
  NEW_QUERY(INNER_JOIN, r, o)
  result.addArg(funcWrap(f))

proc outerJoin*[T, U](r, o: RqlQuery, f: proc(x, y: T): U): RqlQuery =
  ## Returns a left outer join of two sequences
  NEW_QUERY(OUTER_JOIN, r, o)
  result.addArg(funcWrap(f))

proc eqJoin*(r: RqlQuery, s: string, o: RqlQuery, index = "id"): RqlQuery =
  ## Join tables using a field or function on the left-hand
  ## sequence matching primary keys or secondary indexes on the right-hand table
  NEW_QUERY(EQ_JOIN, r, s, o)

  if index != "id":
    result.setOption("index", index)

proc eqJoin*(r: RqlQuery, f: proc(x: RqlQuery): RqlQuery, o: RqlQuery, index = "id"): RqlQuery =
  ## Join tables using a field or function on the left-hand
  ## sequence matching primary keys or secondary indexes on the right-hand table
  NEW_QUERY(EQ_JOIN, r)
  result.addArg(funcWrap(f))
  result.addArg(o)

  if index != "id":
    result.setOption("index", index)

proc zip*(r: RqlQuery): RqlQuery =
  ## Used to ‘zip’ up the result of a join by merging the ‘right’ fields into ‘left’ fields of each member of the sequence.
  NEW_QUERY(ZIP, r)
