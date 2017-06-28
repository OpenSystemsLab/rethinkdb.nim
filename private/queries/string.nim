proc match*(r: RqlQuery, regex: string): RqlQuery =
  NEW_QUERY(MATCH, r, regex)

proc split*(r: RqlQuery, separator = "", maxSplits = 0): RqlQuery =
  NEW_QUERY(SPLIT, r)
  if separator != "":
    result.addArg(separator)
  if maxSplits > 0:
    result.addArg(maxSplits)

proc upcase*(r: RqlQuery): RqlQuery =
  NEW_QUERY(UPCASE, r)

proc downcase*(r: RqlQuery): RqlQuery =
  NEW_QUERY(DOWNCASE, r)
