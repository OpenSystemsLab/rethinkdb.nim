proc match*(r: RqlQuery, regex: string): RqlQuery =
  newQueryAst(MATCH, r, regex)

proc split*(r: RqlQuery, separator = "", maxSplits = 0): RqlQuery =
  newQueryAst(SPLIT, r)
  if separator != "":
    result.addArg(separator)
  if maxSplits > 0:
    result.addArg(maxSplits)

proc upcase*(r: RqlQuery): RqlQuery =
  newQueryAst(UPCASE, r)

proc downcase*(r: RqlQuery): RqlQuery =
  newQueryAst(DOWNCASE, r)
