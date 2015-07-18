#--------------------
# Document manipulation
#--------------------

proc row*[T](r: T): RqlRow =
  ## Returns the currently visited document
  ##
  ## This proc must be called along with `[]` operator
  newQueryAst(BRACKET)
  result.firstVar = true

  when r is RethinkClient:
    result.addArg(newQuery(IMPLICIT_VAR))
  else:
    result.addArg(r)
