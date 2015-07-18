#--------------------
# Transformations
#--------------------
proc map*[T, U, V](r: T, f: proc(x: U): V): RqlQuery =
  newQueryAst(MAP, r)

  let res = funcWrap(f)
  result.addArg(res)
