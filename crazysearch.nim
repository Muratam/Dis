import tables, strformat
# f(x,y) の結果(f(0,0),f(0,1),f(0,2),f(1,0)...f(2,2))を返す
var funs = initTable[string, string]()
funs["000111222"] = "x"
funs["012012012"] = "y"
funs["111111111"] = "1"
while true:
  var next = funs
  var preLen = next.len
  # v1 - v2
  for k1, v1 in funs:
    let f2 = funs
    for k2, v2 in f2:
      var newK = ""
      for i in 0..<k1.len:
        let c1 = k1[i]
        let c2 = k2[i]
        if c1 == '0' and c2 == '0': newK &= '1'
        if c1 == '0' and c2 == '1': newK &= '0'
        if c1 == '0' and c2 == '2': newK &= '0'
        if c1 == '1' and c2 == '0': newK &= '1'
        if c1 == '1' and c2 == '1': newK &= '0'
        if c1 == '1' and c2 == '2': newK &= '2'
        if c1 == '2' and c2 == '0': newK &= '2'
        if c1 == '2' and c2 == '1': newK &= '2'
        if c1 == '2' and c2 == '2': newK &= '1'
      if newK in next: continue
      let newV = fmt"crz({v1},{v2})"
      next[newK] = newV
  if next.len == preLen : break
  funs = next
  echo next.len
proc checkAll() =
  proc check(k, ok: string) : bool =
    for i, c in k:
      if ok[i] == '*': continue
      if k[i] != ok[i]: return false
    return true
  for k, v in funs:
    if k.check("00*11*012"):
      echo fmt"OK! {k} : {v}"
    if k.check("00*01211*"):
      echo fmt"OK! {k} : {v}"
  echo "check failed..."
# echo funs
checkAll()
