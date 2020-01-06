import nimbench, tables, sets

type
  DatumPair = (string, int)

var
  s: seq[DatumPair]
  t = initTable[string, int]()
  st = initHashSet[DatumPair]()

bench(insert_seq, m):
  for i in 1..m:
    s.add(($i, i))

bench(insert_table, m):
  for i in 1..m:
    t[$i] = i

bench(insert_set, m):
  for i in 1..m:
    st.incl(($i, i))

{.checks: off, optimization: speed.}
bench(loop_seq, m):
  var v: int
  for i in 1..m:
    for p in s:
      v = p[1]
  doNotOptimizeAway(v)

bench(loop_table, m):
  var v: int
  for i in 1..m:
    for _, p in t.pairs:
      v = p
  doNotOptimizeAway(v)

bench(loop_set, m):
  var v: int
  for i in 1..m:
    for p in st:
      v = p[1]
  doNotOptimizeAway(v)

runBenchmarks()
