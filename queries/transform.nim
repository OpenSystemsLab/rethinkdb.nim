#--------------------
# Transformations
#--------------------
proc map*[T, U, V](r: T, f: proc(x: U): V): RqlQuery =
  ast(r, MAP)

  let res = funcWrap(f)
  result.addArg(res)
