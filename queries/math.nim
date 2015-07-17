#--------------------
# Math and logic
#--------------------

proc `+`*[T, U](r: T, b: U): RqlQuery =
  ## Sum two numbers, concatenate two strings, or concatenate 2 arrays
  ast(r, ADD, b)

proc `-`*[T](r: RqlQuery, b: T): RqlQuery =
  ## Subtract two numbers.
  ast(r, SUB, b)

proc `*`*[T](r: RqlQuery, b: T): RqlQuery =
  ## Multiply two numbers, or make a periodic array.
  ast(r, MUL, b)

proc `/`*[T](r: RqlQuery, b: T): RqlQuery =
  ## Divide two numbers.
  ast(r, DIV, b)

proc `%`*[T](r: RqlQuery, b: T): RqlQuery =
  ## Find the remainder when dividing two numbers.
  ast(r, MOD, b)

proc `and`*[T](r: RqlRow, b: T): expr =
  ## Compute the logical “and” of two or more values
  ast(r, AND, b)

proc `&`*[T](r: RqlRow, e: T): expr =
  ## Shortcut for `and`
  r and e

proc `or`*[T](r: RqlQuery, b: T): RqlQuery =
  ## Compute the logical “or” of two or more values.
  ast(r, OR, b)

proc `|`*[T](r: RqlRow, e: T): expr =
  ## Shortcut for `or`
  r or e

proc `eq`*[T](r: RqlRow, e: T): RqlQuery =
  ## Test if two values are equal.
  let t = r.expr(e).term
  ast(r, EQ, t)

proc `==`*[T](r: RqlRow, e: T): expr =
  ## Shortcut for `eq`
  r.eq(e)

proc `ne`*[T](r: RqlRow, e: T): RqlQuery =
  ## Test if two values are not equal.
  let t = r.expr(e).term
  ast(r, NE, t)

proc `!=`*[T](r: RqlRow, e: T): expr =
  ## Shortcut for `ne`
  r.ne(e)

proc `gt`*[T](r: RqlRow, e: T): RqlQuery =
  ## Test if the first value is greater than other.
  let t = r.expr(e).term
  ast(r, GT, t)

proc `>`*[T](r: RqlRow, e: T): expr =
  ## Shortcut for `gt`
  r.gt(e)

proc `ge`*[T](r: RqlRow, e: T): RqlQuery =
  ## Test if the first value is greater than or equal to other.
  let t = r.expr(e).term
  ast(r, GE, t)

proc `>=`*[T](r: RqlRow, e: T): expr =
  ## Shortcut for `ge`
  r.ge(e)

proc `lt`*[T](r: RqlRow, e: T): RqlQuery =
  ## Test if the first value is less than other.
  let t = r.expr(e).term
  ast(r, LT, t)

proc `<`*[T](e: T, r: RqlRow): expr =
  ## Shortcut for `lt`
  r.gt(e)

proc `le`*[T](r: RqlRow, e: T): RqlQuery =
  ## Test if the first value is less than or equal to other.
  let t = r.expr(e).term
  ast(r, LE, t)

proc `<=`*[T](e: T, r: RqlRow): expr =
  ## Shortcut for `le`
  r.ge(e)

proc `not`*[T](r: RqlRow, e: T): RqlQuery =
  ## Compute the logical inverse (not) of an expression.
  let t = r.expr(e).term
  ast(r, NOT, t)

proc `~`*[T](r: RqlRow, e: T): expr =
  ## Shortcut for `not`
  r not e

proc random*(r: RethinkClient, x = 0, y = 1, isFloat = false): RqlQuery =
  ## Generate a random number between given (or implied) bounds.
  ast(r, RANDOM)

  if x != 0:
    result.addArg(@x)
  if x != 0 and y != 1:
    result.addArg(@y)
  if isFloat:
    result.setOptions(&*{"float": isFloat})
