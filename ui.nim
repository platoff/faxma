
proc JSrender(p: pointer) {.importc.}

import dbmonster, dom, strutils
import times, random, diff, bytes

randomize(2543543)

var a = initDOMBuilder()
var b = initDOMBuilder()
var patch = initPatch()

const ITERS = 1000
let start = cpuTime()

for i in 0..<ITERS:
  patch.clear()
  let data = getData()
  if i mod 2 == 1:
    b.clear()
    data.render(b)
    patch.diff(b.current, a.current)
  else:
    a.clear()
    data.render(a)
    patch.diff(a.current, b.current)
  patch.done()
  
  #echo "patch: ", initBytes(patch.data.head, patch.data.mem)
  JSrender(patch.data.head)

echo "Iteration time: ", formatFloat((cpuTime() - start) * 1000 / ITERS, ffDecimal, 3), " ms"

