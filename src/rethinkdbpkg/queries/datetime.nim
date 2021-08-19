proc now*[T](r: T): RqlQuery =
  NEW_QUERY(NOW)

proc time*[T](r: T, year, month, day: int, timezone: string): RqlQuery =
  NEW_QUERY(TIME, year, month, day, timezone)

proc time*[T](r: T, year, month, day, hour, minute, second: int, timezone: string): RqlQuery =
  NEW_QUERY(TIME, year, month, day, hour, minute, second, timezone)

proc epochTime*[T](r: T, e: int): RqlQuery =
  NEW_QUERY(EPOCH_TIME, r, e)

proc iso8601*[T](r: T, date: string, defaultTimezone = ""): RqlQuery =
  NEW_QUERY(ISO8601, r, date)
  if defaultTimezone != "":
    result.addArg("default_timezone", defaultTimezone)

proc inTimezone*(r: RqlQuery, tz: string): RqlQuery =
  NEW_QUERY(IN_TIMEZONE, r, tz)

proc timezone*(r: RqlQuery): RqlQuery =
  NEW_QUERY(TIMEZONE, r)

proc during*(r: RqlQuery, startTime, endTime: RqlQuery, leftBound = "closed", rightBound = "open"): RqlQuery =
  NEW_QUERY(DURING, r, startTime, endTime)
  if leftBound != "closed":
    result.setOption("left_bound", leftBound)
  if rightBound != "open":
    result.setOption("right_bound", rightBound)

proc date*(r: RqlQuery): RqlQuery =
  NEW_QUERY(DATE, r)

proc timeOfDay*(r: RqlQuery): RqlQuery =
  NEW_QUERY(TIME_OF_DAY, r)

proc year*(r: RqlQuery): RqlQuery =
  NEW_QUERY(YEAR, r)

proc month*(r: RqlQuery): RqlQuery =
  NEW_QUERY(MONTH, r)

proc day*(r: RqlQuery): RqlQuery =
  NEW_QUERY(DAY, r)

proc dayOfWeek*(r: RqlQuery): RqlQuery =
  NEW_QUERY(DAY_OF_WEEK, r)

proc dayOfYear*(r: RqlQuery): RqlQuery =
  NEW_QUERY(DAY_OF_YEAR, r)

proc hours*(r: RqlQuery): RqlQuery =
  NEW_QUERY(HOURS, r)

proc minutes*(r: RqlQuery): RqlQuery =
  NEW_QUERY(MINUTES, r)

proc seconds*(r: RqlQuery): RqlQuery =
  NEW_QUERY(SECONDS, r)

proc toIso8601*(r: RqlQuery): RqlQuery =
  NEW_QUERY(TO_ISO8601, r)

proc toEpochTime*(r: RqlQuery): RqlQuery =
  NEW_QUERY(TO_EPOCH_TIME, r)
