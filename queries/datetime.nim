proc now*[T](r: T): RqlQuery =
  newQueryAst(NOW)

proc time*[T](r: T, year, month, day: int, timezone: string): RqlQuery =
  newQueryAst(TIME, year, month, day, timezone)

proc time*[T](r: T, year, month, day, hour, minute, second: int, timezone: string): RqlQuery =
  newQueryAst(TIME, year, month, day, hour, minute, second, timezone)

proc epochTime*[T](r: T, e: int): RqlQuery =
  newQueryAst(EPOCH_TIME, r, e)

proc iso8601*[T](r: T, date: string, defaultTimezone = ""): RqlQuery =
  newQueryAst(ISO8601, r, date)
  if defaultTimezone != "":
    result.addArg("default_timezone", defaultTimezone)

proc inTimezone*(r: RqlQuery, tz: string): RqlQuery =
  newQueryAst(IN_TIMEZONE, r, tz)

proc timezone*(r: RqlQuery): RqlQuery =
  newQueryAst(TIMEZONE, r)

proc during*(r: RqlQuery, startTime, endTime: RqlQuery, leftBound = "closed", rightBound = "open"): RqlQuery =
  newQueryAst(DURING, r, startTime, endTime)
  if leftBound != "closed":
    result.setOption("left_bound", leftBound)
  if rightBound != "open":
    result.setOption("right_bound", rightBound)

proc date*(r: RqlQuery): RqlQuery =
  newQueryAst(DATE, r)

proc timeOfDay*(r: RqlQuery): RqlQuery =
  newQueryAst(TIME_OF_DAY, r)

proc year*(r: RqlQuery): RqlQuery =
  newQueryAst(YEAR, r)

proc month*(r: RqlQuery): RqlQuery =
  newQueryAst(MONTH, r)

proc day*(r: RqlQuery): RqlQuery =
  newQueryAst(DAY, r)

proc dayOfWeek*(r: RqlQuery): RqlQuery =
  newQueryAst(DAY_OF_WEEK, r)

proc dayOfYear*(r: RqlQuery): RqlQuery =
  newQueryAst(DAY_OF_YEAR, r)

proc hours*(r: RqlQuery): RqlQuery =
  newQueryAst(HOURS, r)

proc minutes*(r: RqlQuery): RqlQuery =
  newQueryAst(MINUTES, r)

proc seconds*(r: RqlQuery): RqlQuery =
  newQueryAst(SECONDS, r)

proc toIso8601*(r: RqlQuery): RqlQuery =
  newQueryAst(TO_ISO8601, r)

proc toEpochTime*(r: RqlQuery): RqlQuery =
  newQueryAst(TO_EPOCH_TIME, r)
