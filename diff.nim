

import dom, htmltags, strutils

type
  Action = enum
    halt
    navUp
    navKid
    navParent
    navGrandParent
    navFirstChild
    navSecondChild
    navNextSibling
    elAppend
    elRemoveLast
    elRemoveMany
    attrSet
    attrRemove

  Patch = object
    patchPath: array[256, int]
    patchLen: int
    scanPath: array[256, int]
    scanLen: int
    data*: Buf

proc initPatch*(): Patch =
  result.data.initBuf(1024*1024)

proc clear*(patch: var Patch) =
  patch.patchLen = 0
  patch.scanLen = 0
  patch.data.clear()

template navigateUp(patch: var Patch, times: int) =
  case times:
    of 0: discard
    of 1: 
      patch.data.push int(navParent)
    of 2:
      patch.data.push int(navGrandParent)    
    else:
      patch.data.push int(navUp)
      patch.data.push times

template navigateSibling(patch: var Patch) =
  patch.data.push int(navNextSibling)

template navigateKid(patch: var Patch, kid: int) =
  case kid
  of 0:
    patch.data.push int(navFirstChild)
  of 1:
    patch.data.push int(navSecondChild)
  else:
    patch.data.push int(navKid)
    patch.data.push kid

proc navigateChildren(patch: var Patch, pos: int) =
  for i in pos..< patch.scanLen:
    patch.patchPath[i] = patch.scanPath[i] 
    patch.navigateKid(patch.scanPath[i])
  patch.patchLen = patch.scanLen  

proc navigate(patch: var Patch) =
  # render navigation commands to take me from `patchPath` to `scanPath`
  let len = min(patch.patchLen, patch.scanLen)
  var prefixLen = 0
  while prefixLen < len and patch.patchPath[prefixLen] == patch.scanPath[prefixLen]: inc(prefixLen)
  
  #echo "navigate: ", patch.patchPath, " -> ", patch.scanPath, " common: ", prefixLen
  if patch.patchLen > prefixLen:
      # check next sibling
    if patch.scanLen > prefixLen and patch.scanPath[prefixLen] == patch.patchPath[prefixLen] + 1:
      patch.navigateUp(patch.patchLen - prefixLen - 1)
      patch.navigateSibling()
      patch.navigateChildren(prefixLen + 1)
      patch.patchPath = patch.scanPath      
    else:
      patch.navigateUp(patch.patchLen - prefixLen)
      patch.navigateChildren(prefixLen)
  else:
    patch.navigateChildren(prefixLen)

proc patchElementReplace(patch: var Patch, dst, src: Element) = 
  echo "patch element replace"

proc patchElementAdd(patch: var Patch, e: Element) = 
  patch.navigate()
  #echo "patch-append: ", e #toHex(cast[int](e))
  patch.data.push int(elAppend)
  patch.data.push cast[int](e)

proc patchElementRemoveChildren(patch: var Patch, n: int) = 
  patch.navigate()
  if n == 1:
    patch.data.push int(elRemoveLast)
  else:
    patch.data.push int(elRemoveMany)
    patch.data.push n

proc patchSetAttribute(patch: var Patch, attr: Attribute) = 
  patch.navigate()
  patch.data.push int(attrSet)
  patch.data.push int(attr.attr)
  patch.data.push cast[int](attr.value)

proc patchRemoveAttribute(patch: var Patch, attr: int) = 
  patch.navigate()
  patch.data.push int(attrRemove)
  patch.data.push int(attr)

proc diffAttrs(patch: var Patch, dst, src: Element) = 
  var dI, sI: int
  let dA = dst.attrs
  let sA = src.attrs

  while dI < dst.nAttrs and sI < src.nAttrs: 
    let c = cmp(dA[dI].attr, sA[si].attr)
    if c == 0:
      if dA[dI].value != sA[si].value:
        patch.patchSetAttribute(dA[dI])
      inc dI
      inc sI
    elif c < 0:
      # new attribute at destination
      patch.patchSetAttribute(dA[dI])
      inc dI
    else:
      # attribute removed at destination
      patch.patchRemoveAttribute(sA[sI].attr)
      inc sI

  for i in dI..<dst.nAttrs:
    patch.patchSetAttribute(dA[dI])

  for i in sI..<src.nAttrs:
    patch.patchRemoveAttribute(sA[sI].attr)

proc diff*(patch: var Patch, dst, src: Element) 

proc diffChildren(patch: var Patch, dst, src: Element) = 
  var i = 0
  let d = dst.kids
  let s = src.kids

  # move down
  # echo "move down"
  inc patch.scanLen

  while i < dst.nKids and i < src.nKids: 
    patch.scanPath[patch.scanLen - 1] = i
    diff(patch, d[i], s[i])
    inc i

  # moving up
  # echo "move up"
  dec patch.scanLen

  if dst.nKids > src.nKids:    
    for j in i..<dst.nKids:
      patch.patchElementAdd(d[j])
  elif src.nKids > dst.nKids:
    patch.patchElementRemoveChildren(src.nKids - i)

proc diff*(patch: var Patch, dst, src: Element) =
  if dst.tag != int(Tag.DOCUMENT_ROOT):
    if dst.tag == src.tag:
      patch.diffAttrs(dst, src)
    else:
      patch.patchElementReplace(dst, src)
  
  diffChildren(patch, dst, src)

proc done*(patch: var Patch) =
  patch.data.push(0)

when isMainModule:

  import dbmonster, times

  GC_Disable()


  var a = initDOMBuilder()
  var b = initDOMBuilder()
  var patch = initPatch()

  const ITERS = 1000
  let start = cpuTime()

  for i in 0..<ITERS:
    GC_Enable()
    let x = newString(0)
    GC_Disable()
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
    #echo "PATCH SIZE: ", patch.data.mem

  echo "Iteration time: ", formatFloat((cpuTime() - start) * 1000 / ITERS, ffDecimal, 3), " ms"
