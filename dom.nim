
import htmltags
import xas
import strutils

type
  Attribute* = object
    attr*: Attr
    value*: cstring

  Attributes = ptr array[1_000, Attribute]

  Element* = ptr ElementObj
  ElementObj = object
    tag*: Tag
    nKids*: int
    nAttrs*: int

  Buf = object
    head: pointer
    tail: pointer

  DOMBuilder = object
    current: Element
    contentStack: Buf
    elements: Buf
    dom: Buf

template push[T](buf: var Buf, val: T) = 
  cast[ptr T](buf.tail)[] = val
  buf.tail = cast[pointer](cast[int](buf.tail) +% sizeof(T))

proc pop(buf: var Buf, T: typedesc): T {.inline.} =
  buf.tail = cast[pointer](cast[int](buf.tail) -% sizeof(T))
  cast[ptr T](buf.tail)[]

template write(buf: var Buf, data: pointer, size: int) =
  copyMem(buf.tail, data, size)
  buf.tail = cast[pointer](cast[int](buf.tail) +% size)

template advance(buf: var Buf, size: int) =
  buf.tail = cast[pointer](cast[int](buf.tail) +% size)

template trim(buf: var Buf, newTail: pointer) =
  buf.tail = newTail

proc mem(buf: Buf): int = cast[int](buf.tail) -% cast[int](buf.head)

template size(e: Element): int = 
  sizeof(ElementObj) + (sizeof(Attribute) * e.nAttrs) + (sizeof(Element) * e.nKids)

template attrs*(e: Element): Attributes =
  cast[Attributes](cast[int](e) +% sizeof(ElementObj))

proc openTag(builder: var DOMBuilder, tag: Tag) =
  builder.elements.push builder.current
  builder.current = cast[Element](builder.contentStack.tail)
  builder.contentStack.advance sizeof ElementObj
  builder.current.tag = tag
  builder.current.nAttrs = 0
  builder.current.nKids = 0

proc closeTag(builder: var DOMBuilder) =
  let res = cast[Element](builder.dom.tail) 
  builder.dom.write(builder.current, builder.current.size)
  builder.contentStack.trim(builder.current)
  builder.contentStack.push res
  builder.current = builder.elements.pop(Element)
  inc builder.current.nKids

proc attr(builder: var DOMBuilder, attr: Attr, value: cstring) =
  builder.contentStack.push attr
  builder.contentStack.push value
  inc builder.current.nAttrs
  when true:
    let attrs = builder.current.attrs
    var i = builder.current.nAttrs - 1
    while i >= 0:
      if int(attrs[i].attr) > int(attrs[i+1].attr):
        swap(attrs[i].attr, attrs[i+1].attr)
        swap(attrs[i].value, attrs[i+1].value)
        dec i
      else:
        break

proc initBuf(buf: var Buf, size: int) =
  buf.head = alloc(size)
  buf.tail = buf.head

proc initDomBuilder(): DOMBuilder =
  initBuf(result.contentStack, 1024*1024)
  initBuf(result.elements, 8*1024)
  initBuf(result.dom, 16*1024*1024)
  openTag(result, Tag.p) # document root

proc free(buf: var Buf) =
  dealloc(buf.head)
  buf.head = nil
  buf.tail = nil

proc reset(buf: var Buf) =
  buf.tail = buf.head

proc free(builder: var DOMBuilder) =
  free(builder.contentStack)
  free(builder.elements)
  free(builder.dom)

proc reset(builder: var DOMBuilder) =
  reset(builder.contentStack)
  reset(builder.elements)
  reset(builder.dom)
  openTag(builder, Tag.p) # document root

proc `$`*(builder: DOMBuilder): string =
  result = "Memory usage: "
  result.add $builder.contentStack.mem
  result.add ", "
  result.add $builder.elements.mem
  result.add ", "
  result.add $builder.dom.mem

var builder = initDomBuilder()
for j in 0..1000:
  for i in 0..1000:
    builder.openTag(Tag.section)
    builder.attr Attr.value, "title"
    builder.attr Attr.title, "title"
    builder.attr Attr.class, "xxx"
    builder.attr Attr.width, "vvvvvv"
    builder.openTag(Tag.p)
    builder.attr Attr.class, "yyy"
    builder.attr Attr.value, "title"
    builder.attr Attr.placeholder, "vvvvvv"
    builder.attr Attr.title, "title"
    builder.attr Attr.width, "vvvvvv"
    builder.closeTag()
    builder.openTag(Tag.p)
    builder.attr Attr.width, "vvvvvv"
    builder.attr Attr.value, "title"
    builder.attr Attr.class, "zzzzzz"
    builder.attr Attr.placeholder, "vvvvvv"
    builder.attr Attr.title, "title"
    builder.closeTag()
    builder.closeTag()
  builder.reset

echo builder