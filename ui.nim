
proc JSrender(p: pointer) {.importc.}

import dbmonster, dom, strutils
import times, diff, bytes, emscripten

GC_disable()

var a = initDOMBuilder()
var b = initDOMBuilder()
var patch = initPatch()
var i = 0

let start = cpuTime()

proc loop() {.cdecl.} =
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
  #if i mod 60 == 0:
  GC_enable()
  let x = newString(0)
  GC_disable()
  #GC_step 100
  inc i

  if i mod 1000 == 0:
    echo "FPS: ", formatFloat(float(i) / (cpuTime() - start), ffDecimal, 2)
    

emscripten_set_main_loop(loop, 60, 1)

#echo "Iteration time: ", formatFloat((cpuTime() - start) * 1000 / ITERS, ffDecimal, 3), " ms"

