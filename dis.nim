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

proc debugPrint(str:string) =
  stderr.writeLine str
  # discard

proc printMemory(M:seq[int]) =
  var l = 0
  for i, m in M:
    if m != 0: l = i
  debugPrint fmt"size:{l}\n{M[0..<l]}"

proc tritsub(a,b:int) : int =
  for p in [1, 3, 9, 27, 81, 243, 729, 2187, 6561, 19683]:
    result += (a div p mod 3 - b div p mod 3 + 3) mod 3 * p

proc `--`(a,b: int) : int = tritsub(a,b)

proc exec(base: seq[int]) =
  var M = base
  M.printMemory
  let input = stdin.readAll()
  var inputI = 0
  var a = 0
  var c = 0
  var d = 0
  while true:
    debugPrint fmt"{M[c].chr}: c:{c} a:{a} d:{d} M[d]:{M[d]}"
    case M[c]:
    of '*'.int: d = M[d]
    of '^'.int: c = M[d]
    of '>'.int:
      M[d] = M[d] div 3 + (M[d] mod 3) * 19683
      a = M[d]
    of '|'.int:
      M[d] = tritsub(a, M[d])
      a = M[d]
    of '{'.int:
      if a == 59048: return
      debugPrint fmt"OUTPUT: {a}({a.chr})"
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
    .replace("33", "!").replace("42", "*").replace("62", ">")
    .replace("94", "^").replace("95", "_")
    .replace("123", "{").replace("124", "|").replace("125", "}")
    .replace("jump", "^").replace("getc","}").replace("putc","{")
    .replace("halt", "!").replace("load","*").replace("ror", ">").replace("sub", "|")
    .replace("R0", ">__*") # d=34: M[34]をROR
    .replace("R1", "_>_*") # d=34: M[35]をROR
    .replace("R2", "__>*") # d=34: M[36]をROR
    .replace("F1", ">||*") # d=34: 謎1(for hello world)
    .replace("F2", ">_|*") # d=34: 謎2(for hello world)
    .replace("F3", ">|_*") # d=34: 謎3(for hello world)
    .replace("F4", "__|*") # d=34: 謎4(for hello world)
    .replace("P", "{__*")  # d=34: putc(M[34]) (P+R2やPPR2などは結合できるのでたまに結合される)
    .replace("\n","").replace(" ","").strip()
  echo result
  echo result.len

# メモリとコードを同一に置くのはむずすぎるので分ける。
# d = 34,35,36,37,... をメモリとすることで有効活用(sub putc halt...で初期化). 多分長さ50程度は使用できる
# d, つまり見ているメモリ番地が毎回+1されるのでうまく回す。*を呼ぶとd=33へ戻されるのがミソ。
# M[d] はともかく, a も変化する(>|で)ので、単純に置換はできない。 a は保存したが一瞬だけ覚えてる値(for minus)と考えるといい
# | 演算は、ビットごとに独立で、10ビットあるので、うまく使う。
# 入力が取れなくなると終了するので、16倍して死ぬならループを作る(jumpするだけ？)
# getc_x(d) := M[d+1]==0 条件で      : a = M[d+1] = getc
# set_x(d)  := M[d+1]==0 条件で      : M[d+1] = a
# getc_s(n) := cls_s(n+1) して getc_x(n) で : a = M[n+1] = getc
# setc_s(n) := cls_s(n+1) して set_x(n) で : M[n+1] = a

# 以下 d:=34の前提とする
# a = M[n] = M[n] >> 1
var memorySize = 3 # 40くらいまでだがコード長(と実行時間)が線形に増える
proc nop(): string = "_".repeat(memorySize) & "*"
# a = M[n] = M[n] >> 1
proc tritrot_n(n:int) : string =
  result = nop()
  result[n] = '>'
# a = M[n] = a -- M[n]
proc tritsub_n(n:int) :string =
  result = nop()
  result[n] = '|'
# a = a; putc(a)
proc putc_a() : string =
  result = nop()
  result[0] = '{'
# a = getc()
proc getc_a() : string =
  result = nop()
  result[0] = '}'
# a = M[n]
proc load_n(n:int): string = tritrot_n(n).repeat(10)
# a = M[n] = 0
proc clear_n(n:int): string = load_n(n) & tritsub_n(n)
# a = M[n] = getc()
proc getc_n(n:int): string = clear_n(n) & getc_a() & tritsub_n(n)
# a = M[n]; M[m] = M[n];
proc cp_n_m(n, m:int): string = clear_n(m) & load_n(n) & tritsub_n(m)

# 48 = 1210
# 49 = 1211
# a,bを--のみで以下にしたい
#   0--b--b--a--a: 00:0 01:1 10:1 11:2
#   0--b--a: 00:0 01:2 10:2 11:1
# A,c を--のみで以下にしたい
# 00:0 01:0 10:0 11:1 20:1 21:1 (000111)もしくは
# 00:0 01:0 10:1 11:1 20:0 21:1 (001101)
# for a in [0,1,2]:
#   for b in [0,1]:
#     let x = b--a--(a--b)
#     echo fmt"{a}{b}:{x}"
# if true: quit ""
# M[0]=getc M[1]=getc M[2]=getc getc
# M[0]=getc--M[0]...
const prefix = fmt""" jump 33 {"_".repeat(32)} {"33 ".repeat(61)} load"""
let cat = fmt"""load jump {"_".repeat(32)} getc putc load jump {"_".repeat(5)} halt {"_".repeat(2)} load"""
let hello = fmt"""jump 33 {"_".repeat(32)} 124 123 {"33 ".repeat(59)} load
R1 F3 R1 R1 R1 R1 R1 R1 R1 R1 R1 R0 |_>* F4 |||* R2 F1 F2 R2 R2 R2 R2 R2 R2 R2 P
R2 F2 F1 R2 F1 F1 R2 R2 R2 F2 F1 R2 R2 R2 R2 R2 R2 P
F1 F2 R2 R2 F1 F1 R2 F2 F1 R2 R2 R2 R2 R2 R2 R2 P P
R2 F1 F2 R2 R2 R2 R2 R2 R2 R2 R2 R2 P
R2 F2 F1 R2 F2 F1 R2 R2 R2 R2 R2 R2 R2 R2 R2 P
R2 F1 F2 >|>* F1 F2 R2 R2 R2 R2 R2 R2 R2 R2 P
R2 F3 F1 F2 R2 F1 F2 R2 R2 F2 F1 R2 R2 R2 R2 R2 R2 P
F1 F2 R2 F2 F1 R2 F3 F1 F2 R2 R2 R2 R2 R2 R2 R2 R2 P
R2 F3 F1 F1 R2 R2 R2 R2 R2 R2 R2 R2 R2 P
R2 F3 F1 F2 R2 R2 R2 R2 R2 R2 R2 R2 R2 P
R2 F4 >F4 >F4 F4 R2 R2 R2 R2 R2 R2 R2 R2 R2 F2 F1 P
R2 F4 >F4 >F4 P
F4 R2 F1 F1 putc halt"""
let mine = fmt"""{prefix}
{getc_n(0)} {cp_n_m(0,1)} {load_n(1)} {putc_a()}
{getc_n(0)} {cp_n_m(0,1)} {load_n(1)} {putc_a()}
{getc_n(0)} {cp_n_m(0,1)} {load_n(1)} {putc_a()}
{getc_n(0)} {cp_n_m(0,1)} {load_n(1)} {putc_a()}
{getc_n(0)} {cp_n_m(0,1)} {load_n(1)} {putc_a()}
halt
"""
let code = mine
code.preProcess().load().exec()
