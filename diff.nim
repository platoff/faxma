

import dom, htmltags, strutils

type
  Patch = object
    patchPath: seq[int]
    scanPath: seq[int]

proc initPatch*(): Patch =
  result.patchPath = newSeq[int]()
  result.scanPath = newSeq[int]()

# proc commonPrefix(patch: var Patch): int =
#   let len = min(patch.patchPath.len, patch.scanPath.len)
#   var i = 0
  
#   while i < len and patch.patchPath[i] == patch.scanPath[i]:
#     inc(i)
#   result = i

proc navigate(patch: var Patch) =
  # render navigation commands to take me from `patchPath` to `scanPath`
  # let prefix = commonPrefix(patch)
  discard

proc patchElementReplace(patch: var Patch, dst, src: Element) = discard
proc patchElementAdd(patch: var Patch, e: Element) = 
  patch.navigate()
  echo "render: ", toHex(cast[int](e))

proc patchElementRemoveChildren(patch: var Patch, n: int) = discard

proc patchAttributeAdded(patch: var Patch, attr: Attribute) = discard
proc patchAttributeModified(patch: var Patch, attr: Attribute) = discard
proc patchAttributeRemoved(patch: var Patch, attr: Attribute) = discard

proc diffAttrs(patch: var Patch, dst, src: Element) = 
  var dI, sI: int
  let dA = dst.attrs
  let sA = src.attrs

  while dI < dst.nAttrs and sI < src.nAttrs: 
    let c = cmp(dA[dI].attr, sA[si].attr)
    if c == 0:
      if dA[dI].value == sA[si].value:
        patch.patchAttributeModified(dA[dI])
      inc dI
      inc sI
    elif c < 0:
      # new attribute at destination
      patch.patchAttributeAdded(dA[dI])
      inc dI
    else:
      # attribute removed at destination
      patch.patchAttributeRemoved(sA[sI])
      inc sI

  for i in dI..<dst.nAttrs:
    patch.patchAttributeAdded(dA[dI])

  for i in sI..<src.nAttrs:
    patch.patchAttributeRemoved(sA[sI])

proc diff*(patch: var Patch, dst, src: Element) 

proc diffChildren(patch: var Patch, dst, src: Element) = 
  var i = 0
  let d = dst.kids
  let s = src.kids

  patch.scanPath.add(i)

  while i < dst.nKids and i < src.nKids: 
    patch.scanPath[^1] = i
    diff(patch, d[i], s[i])
    inc i

  # moving up
  discard patch.scanPath.pop()

  if dst.nKids > src.nKids:    
    for j in i..<dst.nKids:
      patch.patchElementAdd(d[j])
  elif src.nKids > dst.nKids:
    patch.patchElementRemoveChildren(src.nKids - i)

proc diff*(patch: var Patch, dst, src: Element) =
  if dst.tag != Tag.DOCUMENT_ROOT:
    if dst.tag == src.tag:
      patch.diffAttrs(dst, src)
    else:
      patch.patchElementReplace(dst, src)
  
  diffChildren(patch, dst, src)


