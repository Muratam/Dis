import sequtils, strutils, strformat

proc load(code: string): seq[int] =
  result = newSeq[int](59049)
  var i = 0
  var isComment = false
  for c in code:
    if isComment:
      if c != ')': continue
      isComment = false
    elif c in "*^>|{}_!":
      result[i] = c.int
      i += 1
    elif c in " \n\t": continue
    elif c == '(': isComment = true
    else: quit "invalid character : " & c

proc printMemory(M:seq[int]) =
  var l = 0
  for i, m in M:
    if m != 0: l = i
  stderr.writeLine fmt"size:{l}\n{M[0..<l]}"

proc exec(base: seq[int]) =
  var M = base
  M.printMemory
  let input = stdin.readAll()
  var inputI = 0
  var a = 0
  var c = 0
  var d = 0
  while true:
    stderr.writeLine fmt"{M[c].chr}: c:{c} a:{a} d:{d} M[d]:{M[d]}"
    case M[c]:
    of '*'.int: d = M[d]
    of '^'.int: c = M[d]
    of '>'.int:
      M[d] = M[d] div 3 + (M[d] mod 3) * 19683
      a = M[d]
    of '|'.int:
      var sum = 0
      for p in [1, 3, 9, 27, 81, 243, 729, 2187, 6561, 19683]:
        sum += (a div p mod 3 - M[d] div p mod 3 + 3) mod 3 * p
      M[d] = sum
      a = M[d]
    of '{'.int:
      if a == 59048: return
      stderr.writeLine fmt"OUTPUT: {a}({a.chr})"
      stdout.write a.char
    of '}'.int:
      if inputI >= input.len:
        a = 59048
      else:
        a = input[inputI].int
        inputI += 1
    of '!'.int: return
    # 読めない文字があっても落ちない
    else: discard
    if c == 59048: c = 0
    else: c += 1
    if d == 59048: d = 0
    else: d += 1

proc preProcess(code: string) : string =
  result = code
    .replace("jump", "^").replace("getc","}").replace("putc","{")
    .replace("halt", "!").replace("load","*").replace("ror", ">").replace("sub", "|")
    .replace("fish", "*__>")
    .replace("\n","").replace(" ","").strip()
  echo result

let cat = fmt"""load jump {"_".repeat(32)} getc putc load jump {"_".repeat(5)} halt {"_".repeat(2)} load"""
# d = 34,35,36,37,... をメモリとすることで有効活用 # 34  35   36   37   38
let hello = fmt"""jump halt {"_".repeat(32)}   sub putc halt halt halt {"_".repeat(56)}
*_>_*>|_*_>_*_>_*_>_*_>_*_>_*_>_*_>_*_>_*_>_*>__*|_>*__|*|||*__>*>||*>_|*__>*__>*__>*__>*__>*__>*__>* putc
_>*>_|*>||*__>*>||*>||*__>*__>*__>*>_|*>||*__>*__>*__>*__>*__>*__>* putc
__*>||*>_|*__>*__>*>||*>||*__>*>_|*>||*__>*__>*__>*__>*__>*__>*__>* putc putc
>*>||*>_|*__>*__>*__>*__>*__>*__>*__>*__>*__>* putc
_>*>_|*>||*__>*>_|*>||*__>*__>*__>*__>*__>*__>*__>*__>*__>* putc
_>*>||*>_|*>|>*>||*>_|*__>*__>*__>*__>*__>*__>*__>*__>* putc
_>*>|_*>||*>_|*__>*>||*>_|*__>*__>*>_|*>||*__>*__>*__>*__>*__>*__>* putc
__*>||*>_|*__>*>_|*>||*__>*>|_*>||*>_|*__>*__>*__>*__>*__>*__>*__>*__>* putc
_>*>|_*>||*>||*__>*__>*__>*__>*__>*__>*__>*__>*__>* putc
_>*>|_*>||*>_|*__>*__>*__>*__>*__>*__>*__>*__>*__>* putc
_>*__|*>__|*>__|*__|*__>*__>*__>*__>*__>*__>*__>*__>*__>*>_|*>||* putc
_>*__|*>__|*>__|* putc
_|*__>*>||*>||* putc halt"""
let code = hello
code.preProcess().load().exec()
