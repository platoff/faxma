
import hashes

type
  HugeArray[T] = ptr array[1_000_000, T] 
  Subseq[T] = object
    arr: HugeArray[T]
    rng: Slice[int]

proc len[T](rng: Slice[T]): T = rng.b - rng.a

proc len[T](s: Subseq[T]): int = len s.rng

proc `[]`[T](s: Subseq[T], i: int): T =
  assert i >= 0 and i < len(s.rng) 
  s.arr[s.rng.a + i]

proc subseq[T](arr: HugeArray[T], rng: Slice[int]): Subseq[T] = 
  result.arr = arr
  result.rng = rng

proc winhash[T](arr: Subseq[T], i, j: int): Hash =
  for k in i..<j:
    result = result !& hash(arr[k])
  result = !$result 

proc equal[T](u: Subseq[T], su: int, v: Subseq[T], sv: int, s: int): bool =
  result = true
  var i = 0
  while i < s:
    if u[su + i] != v[sv + i]:
      result = false
      break
    inc i

proc rollmatch[T](u, v: Subseq[T], s: int, match: var Slice[int]): bool =
  if s <= len(u) and s<=len(v):
#    echo "rollmatch: ", u, " - ", v
    let hu = winhash(u, 0, s)
    var hv = winhash(v, 0, s)
    var i = 0
    while true:
      if hv == hu:
        if equal(u, 0, v, i, s):
          var j = i + s
          while j < v.len and (j - i < u.len) and (v[j] == u[j - i]): inc j # Greedy extension of match
          match = i..j
          result = true
          break
      inc i
      if i + s <= len(v):
        hv = winhash(v, i, i + s) # need roll in future
      else:
        break 

type
  OpKind = enum
    ins
    cpy

  Operation = object
    kind: OpKind
    rng: Slice[int]

  Matchlist[T] = object
    name: string
    arr: HugeArray[T]
    list: seq[Operation]

proc `$`(op: Operation): string = "<" & $op.kind & " " & $op.rng.a & ", " & $op.rng.b & ">"  

proc `$`[T](s: Subseq[T]): string =
  result = ""
  for i in s.rng.a..<s.rng.b:
    result.add $s.arr[i] & ", "

proc `$`(ml: Matchlist): string =
  result = ml.name & ": "
  for i in ml.list:
    result.add $i #& " " & $subseq(ml.arr, i.rng)

proc len(op: Operation): int = len op.rng

proc insertOp(rng: Slice[int]): Operation =
  if rng.a < 0 or rng.b < 0:
    quit "oops"
  result.kind = ins
  result.rng = rng

proc copyOp(rng: Slice[int]): Operation =
  if rng.a < 0 or rng.b < 0:
    quit "oops"
  result.kind = cpy
  result.rng = rng

proc remove[T](ml: var Matchlist[T], c: int): Operation = 
#  echo "remove ", c, " from ", ml
  result = ml.list[c]
  ml.list.delete(c)

proc insert[T](ml: var Matchlist[T], op: Operation, c: int) =
  echo "insert at ", c, " op ", op, " list: ", ml
  if c > 0 and c <= ml.list.len:
    let target = ml.list[c-1] 
    echo "try to join target: ", target, " op: ", op
    if target.kind == op.kind and target.rng.b == op.rng.a:
      echo "hoorah! joining"
      ml.list[c-1].rng.b = op.rng.b
      return
  if c == ml.list.len:
    ml.list.add(op)
  else:
    ml.list.insert(op, c)    

proc findmatch[T](u: Subseq[T], v: var Matchlist[T], s: int, p: var int): Operation =
  echo "looking for ", u, " match in ", v, "p: ", p
  var delta = 0 
  while true:
    let i = p + delta 
    if i >= 0 and i < v.list.len:
      let op = v.list[i]
      if op.kind == ins:
        var match: Slice[int]
        let subs = subseq(v.arr, op.rng)
        #echo "scanning: ", subs
        if rollmatch(u, subs, s, match):
          #echo "FOUND!"
          let r1 = op.rng.a..(op.rng.a + match.a)
          let r2 = (op.rng.a + match.b)..op.rng.b
          let copy = (op.rng.a + match.a)..(op.rng.a + match.b)
          echo "match found! replacing: ", v.list[i], " match: ", match, " with ", r1, " ", r2
          v.list[i].rng = r1
          v.insert(insertOp(r2), i+1)
          result = copyOp(copy)
          echo "return copy: ", copy
          p = i
          break
    if delta > 0:
      delta = -delta
    elif delta == 0:
      delta = 1
    else:
      delta = 1 - delta
      if delta > v.list.len:
        p = -1
        break

proc match[T](u, v: var Matchlist[T], s: int) =
  var cu = 0
  var p = -1
  while cu < u.list.len:
    echo "MATCH ", u.list[cu], " from ", u
    let t = u.remove(cu)
    if t.kind == cpy:
      u.insert(t, cu)
    else:
      let subs = subseq(u.arr, t.rng)
      let c = findmatch(subs, v, s, p)
      if p != -1:        
        insert(u, c, cu)
        insert(u, insertOp((t.rng.a + c.len)..t.rng.b), cu + 1)
        echo "matchlist: ", cu, " ", u        
      else:
        if t.rng.len > s:
          echo "SPLIT!"
          let op1 = insertOp(t.rng.a..(t.rng.a + s))
          insert(u, op1, cu)
          let op2 = insertOp((t.rng.a + s)..t.rng.b)
          insert(u.list, op2, cu + 1)
        else:
          insert(u, t, cu)
        echo "more intervals: ", cu, " ", u        
    inc cu

type
  Test = enum
    SEr, SEa, SEc, EEc, SEd, EEd, SEe, EEe, EEa, SEb, SEf, EEf, EEb, EEr, SEi, EEi, SErr, EErr

var s0 = @[SEr, SEa, SEc, EEc, SEd, EEd, SEe, EEe, EEa, SEb, SEf, EEf, EEb, EEr]
var s1 = @[SErr, SEb, SEf, EEf, EEb, SEa, SEc, EEc, SEd, EEd, EEa, SEi, EEi, EErr]

proc initMatchlist[T](name: string, s: var openarray[T]): Matchlist[T] =
  result.name = name
  result.arr = cast[HugeArray[T]](addr s[0])
  result.list = newSeq[Operation]()
  result.list.add insertOp(0..s.len)

var u = initMatchlist("s1", s1)
var v = initMatchlist("s0", s0)

match(u, v, 2)

echo u
echo v

match(u, v, 1)

echo u
echo v
