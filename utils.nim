import macros

macro ast*(n: varargs[expr]): stmt =
  result = newNimNode(nnkStmtList, n)
  # new(result)
  result.add(newCall("new", ident("result")))
  # result.conn = r. conn
  result.add(
    newAssignment(
      newDotExpr(ident("result"), ident("conn")),
      newDotExpr(n[0], ident("conn"))
    )
  )
  # result.term = newTerm(tt)
  result.add(
    newAssignment(
      newDotExpr(ident("result"), ident("term")),
      newCall("newTerm", n[1])
    )
  )

  # result.addArg(r.term)
  result.add(newCall("addArg", ident("result"), newDotExpr(n[0], ident("term"))))
  if n.len > 2:
    for i in 2..n.len-1:
      result.add(newCall("addArg", ident("result"), prefix(n[i], "@")))
