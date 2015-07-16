#--------------------
# Document manipulation
#--------------------

proc row*[T: RethinkClient|RqlQuery](r: T): RqlRow =
  ## Returns the currently visited document
  ##
  ## This proc must be called along with `[]` operator
  let t = newTerm(IMPLICIT_VAR)
  ast(r, BRACKET, t)
  result.firstVar = true
