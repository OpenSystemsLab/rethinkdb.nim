#--------------------
# Document manipulation
#--------------------

proc row*[T](r: T): RqlRow =
  ## Returns the currently visited document
  ##
  ## This proc must be called along with `[]` operator
  ast(r, BRACKET)
  result.firstVar = true

  when r is RqlVariable:
    result.addArg(makeVar(r.id))
  else:
    result.addArg(newTerm(IMPLICIT_VAR))
