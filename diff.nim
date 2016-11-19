

import dom

type
  Patch = object

# patch whole element
proc patchElement(patch: var Patch, dst, src: Element) = discard

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

proc diff(patch: var Patch, dst, src: Element) = 
  if dst.tag == src.tag:
    patch.diffAttrs(dst, src)
  else:
    # tag changed
    patch.patchElement(dst, src)

