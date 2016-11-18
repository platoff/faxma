
import macros, hashes, htmltags
    
type
  Html* = object
    events: seq[XAS]
  
  XASKind = enum
    xaSE, xaEE,
    xaAT, xaCAT,
    xaTX, xaCTX,
    xaDH,
    xaXAS
    
  DH = proc (x: int): int {.cdecl.}
  
  XAS* = object
    case kind: XASKind
    of xaSE, xaEE:
      tag: Tag
    of xaAT:
      attr: Attr
      value: string
    of xaCAT:
      cattr: Attr
      cvalue: cstring
    of xaTX:
      text: string
    of xaCTX:
      ctext: cstring
    of xaDH:
      event: int
      handler: DH
    of xaXAS:
      events: ptr Html
      kidsHash: Hash
      
proc hash*(e: XAS): Hash =
  result = hash(e.kind)
  result = result !& (case e.kind
    of xaSE, xaEE: hash(e.tag)
    of xaAT:  hash(e.attr) !& hash(e.value)
    of xaCAT: hash(e.cattr) !& hash(e.cvalue)
    of xaTX:  hash(e.text)
    of xaCTX: hash(e.ctext)
    of xaXAS: e.kidsHash
    of xaDH: hash(e.handler)
  )
  result = !$ result

proc initHtml*(html: var Html) =
  html.events = newSeq[XAS]()

proc initHtml*(html: var Html, hashCode: var Hash, arr: openarray[XAS]) =
  html.events = newSeq[XAS](arr.len)
  for i, v in pairs(arr):
    html.events[i] = v
    hashCode = hashCode !& hash(v)

proc add*(html: var Html, e: XAS) {.inline.} =
  html.events.add e

proc `$`*(event: XAS): string =
  result = $event.kind & ": "
  result.add case event.kind
    of xaSE, xaEE: $event.tag
    of xaTX: event.text
    of xaCTX: $event.ctext
    of xaXAS: $(event.events[])
    else: "xxx"
      
proc `$`*(html: Html): string =
  result = "html: " & $html.events

proc toHtmlBuf(html: Html, output: var string, opened: var bool) =

  proc closeIf(output: var string, opened: var bool) {.inline.} =
    if opened:
      output.add '>'
      opened = false
  
  for event in html.events:
    case event.kind
    of xaSE:
      output.closeIf(opened)
      output.add '<'
      output.add $event.tag
      opened = true
    of xaEE:
      if opened:
        output.add "/>"
        opened = false
      else:
        output.add "</"
        output.add $event.tag
        output.add '>'
    of xaAT:
      assert opened, "toHtmlBuf: tag not opened"
      output.add ' '
      output.add $event.attr
      output.add "=\""
      output.add event.value
      output.add '"'
    of xaCAT:
      assert opened, "toHtmlBuf: tag not opened"
      output.add ' '
      output.add $event.cattr
      output.add "=\""
      output.add event.cvalue
      output.add '"'
    of xaTX:
      output.closeIf(opened)
      output.add event.text
    of xaCTX:
      output.closeIf(opened)
      output.add event.ctext
    of xaXAS:
      output.closeIf(opened)
      toHtmlBuf(event.events[], output, opened)
    of xaDH:
      assert false, "not implemented"
    #echo output, " | ", opened, " ev: ", event.kind

proc toHtml*(html: Html): string =
  var opened = false
  result = ""
  toHtmlBuf html, result, opened

proc SE*(tag: Tag): XAS {.inline.} =
  result.kind = xaSE
  result.tag = tag

proc EE*(tag: Tag): XAS {.inline.} =
  result.kind = xaEE
  result.tag = tag

proc AT*(attr: Attr; value: string): XAS {.inline.} =
  result.kind = xaAT
  result.attr = attr
  result.value = value

proc CAT*(attr: Attr; value: cstring): XAS {.inline.} =
  result.kind = xaCAT
  result.cattr = attr
  result.cvalue = value

proc TX*(value: string): XAS {.inline.} =
  result.kind = xaTX
  result.text = value

proc CTX*(value: cstring): XAS {.inline.} =
  result.kind = xaCTX
  result.ctext = value

proc SQ*(html: var Html, hashCode: Hash): XAS =
  result.kind = xaXAS
  result.events = addr html
  result.kidsHash = hashCode

# template staticHtml*(html: expr) {.immediate.} =
#   var 
#     value {.global.}: Html
#     hashCode {.global.}: Hash = 0
#   if hashCode == 0:
#     initHtml(value, hashCode, html)
#     assert hashCode != 0
#   result.add SQ(value, hashCode)

