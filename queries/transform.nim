#--------------------
# Transformations
#--------------------
proc map*[T, U, V](r: T, f: proc(x: U): V): RqlQuery =
  ## Transform each element of one or more sequences by applying a mapping function to them
  newQueryAst(MAP, r)

  let res = funcWrap(f)
  result.addArg(res)

proc withFields*(r: RqlQuery, n: varargs[string, `$`]): RqlQuery =
  ## Plucks one or more attributes from a sequence of objects,
  ## filtering out any objects in the sequence that do not have the specified fields
  newQueryAst(WITH_FIELDS, r)
  for x in n.items():
    result.addArg(x)

proc concatMap*[T, U](r: RqlQuery, f: proc(x: T): U): RqlQuery =
  ## Concatenate one or more elements into a single sequence using a mapping function.
  newQueryAst(CONCAT_MAP, r)
