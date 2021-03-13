import tables, strformat
# f(x,y) の結果(f(0,0),f(0,1),f(0,2),f(1,0)...f(2,2))を返す
var funs = initTable[string, string]()
funs["0011"] = "x"
funs["0101"] = "y"
funs["1111"] = "1"
while true:
  var next = funs
  var preLen = next.len
  # v1 nand v2
  for k1, v1 in funs:
    let f2 = funs
    for k2, v2 in f2:
      var newK = ""
      for i in 0..<k1.len:
        let c1 = k1[i]
        let c2 = k2[i]
        if c1 == '1' and c2 == '1': newK &= '0'
        else: newK &= '1'
      if newK in next: continue
      let newV = fmt"nand({v1},{v2})"
      next[newK] = newV
  if next.len == preLen : break
  funs = next
  echo next.len
echo funs
