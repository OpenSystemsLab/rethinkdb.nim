#--------------------
# Joins
#--------------------

proc innerJoin*(r, o, data: RqlQuery): RqlQuery =
  ## Returns an inner join of two sequences
  ast(r, INNER_JOIN)
