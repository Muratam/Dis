import tables, strformat
# f(x,y) の結果(f(0,0),f(0,1),f(0,2),f(1,0)...f(2,2))を返す
var funs = initTable[string, string]()
funs["000000000111111111222222222"] = "x"
funs["000111222000111222000111222"] = "y"
funs["012012012012012012012012012"] = "z"
funs["111111111111111111111111111"] = "1"
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
        if c1 == c2: newK &= '0'
        elif c2 == '0': newK &= c1
        elif c1 != '0': newK &= c2
        elif c2 == '1': newK &= '2'
        else: newK &= '1'
      if newK in next: continue
      let newV = fmt"{v1}-({v2})"
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
    if k.check("00*01****01*11*************"):
      echo fmt"OK! {k} : {v}"
  echo "check failed..."
echo funs
checkAll()
