proc testBit*(w, i: int): bool {.inline.} =
  result = (w and (1 shl (i %% (8*sizeof(w))))) != 0

proc setBit*[T](w: var T, i: int) {.inline.} =
  w = w or T(1 shl (i %% (8*sizeof(T))))

proc resetBit*[T](w: var T, i: int) {.inline.} =
  w = w and not T(1 shl (i %% (8*sizeof(w))))

proc toInt*(s: string): int =
  result = 0

  var bytesCount = 8

  if s.len != bytesCount:
    raise newException(ValueError, "input string must have extractly " & $bytesCount & " bytes")

  for i in 0..bytesCount-1:
    for j in 0..7:
      var bit = 63-(i*8+j)
      if s[i].int.testBit(7-j):
        result.setBit(bit)

proc toInt32*(s: string): int32 =
  result = 0
  var bytesCount = sizeof(int32)
  if s.len != bytesCount:
    raise newException(ValueError, "input string must have extractly " & $bytesCount & " bytes")

  for i in 0..bytesCount-1:
    for j in 0..7:
      var bit = 31-(i*8+j)
      if s[i].int.testBit(7-j):
        result.setBit(bit)
