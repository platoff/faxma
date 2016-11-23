
import htmltags
import xas
import strutils

type
  Attribute* = object
    attr*: int
    value*: cstring

  Attributes = ptr array[1_000, Attribute]
  Elements = ptr array[100_000, Element]

  Element* = ptr ElementObj
  ElementObj = object
    tag*: int
    nKids*: int
    nAttrs*: int

  Buf* = object
    head*: pointer
    tail: pointer

  DOMBuilder* = object
    current*: Element
    contentStack: Buf
    elements: Buf
    strings: Buf
    dom: Buf

template push*[T](buf: var Buf, val: T) = 
  assert sizeof(T) == sizeof(int)
  cast[ptr T](buf.tail)[] = val
  buf.tail = cast[pointer](cast[int](buf.tail) +% sizeof(T))

proc pop(buf: var Buf, T: typedesc): T {.inline.} =
  buf.tail = cast[pointer](cast[int](buf.tail) -% sizeof(T))
  cast[ptr T](buf.tail)[]

template advance(buf: var Buf, size: int) =
  buf.tail = cast[pointer](cast[int](buf.tail) +% size)

template write(buf: var Buf, data: pointer, size: int) =
  copyMem(buf.tail, data, size)
  advance(buf, size)

template trim(buf: var Buf, newTail: pointer) =
  buf.tail = newTail

template size(e: Element): int = 
  sizeof(ElementObj) + (sizeof(Attribute) * e.nAttrs) + (sizeof(Element) * e.nKids)

template attrs*(e: Element): Attributes =
  cast[Attributes](cast[int](e) +% sizeof(ElementObj))

template kids*(e: Element): Elements =
  cast[Elements](cast[int](e) +% sizeof(ElementObj) +% (sizeof(Attribute) * e.nAttrs))

proc toHtml*(e: Element, output: var string, level: int) =
  output.add spaces(level * 2)
  output.add '<'
  output.add $Tag(e.tag)
  let attrs = e.attrs
  for i in 0..< e.nAttrs:
    output.add ' '
    output.add $Attr(attrs[i].attr)
    output.add "=\""
    output.add attrs[i].value
    output.add '"'
  if e.nKids == 0:
    output.add "/>\n"
  else:
    output.add ">\n"
    let kids = e.kids
    for i in 0..< e.nKids:
      toHtml(kids[i], output, level + 1)
    output.add spaces(level * 2)
    output.add "</"
    output.add $Tag(e.tag)
    output.add ">\n"

proc `$`*(e: Element): string = 
  result = ""
  e.toHtml(result, 0)

proc save(builder: var DOMBuilder, s: string): cstring {.inline.} =
  result = cast[cstring](builder.strings.tail)
  builder.strings.write(cstring(s), s.len + 1)

proc openTag*(builder: var DOMBuilder, tag: Tag) =
  builder.elements.push builder.current
  builder.current = cast[Element](builder.contentStack.tail)
  builder.contentStack.advance sizeof ElementObj
  builder.current.tag = int(tag)
  builder.current.nAttrs = 0
  builder.current.nKids = 0

proc closeTag*(builder: var DOMBuilder) =
  let res = cast[Element](builder.dom.tail)
  builder.dom.write(builder.current, builder.current.size)
  builder.contentStack.trim(builder.current)
  builder.contentStack.push res
  builder.current = builder.elements.pop(Element)
  inc builder.current.nKids

proc attr*(builder: var DOMBuilder, attr: Attr, value: cstring) =
  builder.contentStack.push int(attr)
  builder.contentStack.push value
  inc builder.current.nAttrs
  when false:
    let attrs = builder.current.attrs
    var i = builder.current.nAttrs - 1
    while i >= 0:
      if int(attrs[i].attr) > int(attrs[i+1].attr):
        swap(attrs[i].attr, attrs[i+1].attr)
        swap(attrs[i].value, attrs[i+1].value)
        dec i
      else:
        break
  
proc attrString*(builder: var DOMBuilder, attr: Attr, value: string) {.inline.} =
  attr(builder, attr, builder.save(value))

proc text*(builder: var DOMBuilder, s: cstring) =
  # we can further optimize openTag/closeTag call for leaf nodes, for now let's do simple
  builder.openTag(Tag.TEXT)
  builder.attr(Attr.TEXT, s)
  builder.closeTag()

proc textString*(builder: var DOMBuilder, s: string) {.inline.} =
  text(builder, builder.save(s))

proc done*(builder: var DOMBuilder) =
  let res = cast[Element](builder.dom.tail)
  builder.dom.write(builder.current, builder.current.size)
  builder.contentStack.trim(builder.current)
  builder.contentStack.push res
  builder.current = builder.elements.pop(Element)
  builder.current = builder.contentStack.pop(Element)

proc initBuf*(buf: var Buf, size: int) =
  buf.head = alloc(size)
  buf.tail = buf.head

proc initDOMBuilder*(): DOMBuilder =
  initBuf(result.contentStack, 1024*1024)
  initBuf(result.elements, 8*1024)
  initBuf(result.dom, 1024*1024)
  initBuf(result.strings, 1024*1024)
  openTag(result, Tag.DOCUMENT_ROOT)

proc free(buf: var Buf) =
  dealloc(buf.head)
  buf.head = nil
  buf.tail = nil

proc clear*(buf: var Buf) =
  buf.tail = buf.head

proc free(builder: var DOMBuilder) =
  free(builder.contentStack)
  free(builder.elements)
  free(builder.dom)
  free(builder.strings)

proc clear*(builder: var DOMBuilder) =
  clear(builder.contentStack)
  clear(builder.elements)
  clear(builder.dom)
  clear(builder.strings)
  openTag(builder, Tag.DOCUMENT_ROOT) 

proc mem*(buf: Buf): int = cast[int](buf.tail) -% cast[int](buf.head)

proc `$`*(builder: DOMBuilder): string =
  result = "Memory usage:\n"
  result.add "content stack: " & $builder.contentStack.mem
  result.add "\n"
  result.add "element stack: " & $builder.elements.mem
  result.add "\n"
  result.add "DOM (structure): " & $builder.dom.mem
  result.add "\n"
  result.add "DOM (strings): " & $builder.strings.mem

var builder = initDOMBuilder()
# for j in 0..0:
#   builder.clear()
#   for i in 0..0:
builder.openTag(Tag.section)
builder.attr Attr.width, "vvvvvv"
builder.openTag(Tag.p)
builder.attr Attr.class, "yyy"
builder.attr Attr.value, "title"
builder.attr Attr.placeholder, "vvvvvv"
builder.attr Attr.title, "title"
builder.attr Attr.width, "vvvvvv"
builder.closeTag()
builder.openTag(Tag.a)
builder.attr Attr.width, "vvvvvv"
builder.attr Attr.value, "title"
builder.attr Attr.title, "title"
builder.closeTag()
builder.closeTag()

builder.done()

echo builder

echo builder.current
