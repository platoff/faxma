
import math, mersenne, algorithm, dom, htmltags, strutils

const ROWS = 100

type
  Query* = object
    query*: string
    elapsed*: int
    waiting: bool

  Database* = object 
    name*: string
    queries*: seq[Query]

  Data* = ref object 
    databases*: array[ROWS * 2, Database]

var tw = newMersenneTwister(556)

template random(m: int): untyped =
  int(tw.getNum) %% m

proc getQuery(): Query =
  result.elapsed = random(1500)
  result.waiting = random(2) == 0
  case random(10)
  of 0: result.query = "vacuum"
  of 1..2: result.query = "<IDLE> in transaction"
  else: result.query = "SELECT blah FROM something"

proc getDatabase(name: string): Database =
  result.name = name
  result.queries = newSeq[Query]()
  
  for i in 0..random(10):       
    result.queries.add(getQuery())

  result.queries.sort do (a, b: Query) -> int:
    cmp(b.elapsed, a.elapsed)

proc getData*(): Data =
  new result
  for i in 0..< ROWS:
    result.databases[i*2] = getDatabase("cluster" & $(i+1))
    result.databases[i*2+1] = getDatabase("cluster" & $(i+1) & " slave")

#
# Generate DOM
#

proc className(db: Database): cstring =
  if db.queries.len >= 20:
    result = "label label-important"
  elif db.queries.len >= 10:
    result = "label label-warning"
  else:
    result = "label label-success"
  
proc className(q: Query): cstring =
  if q.elapsed >= 1000:
    result = "Query elapsed warn_long"
  elif q.elapsed >= 100:
    result = "Query elapsed warn"
  else:
    result = "Query elapsed short"

proc render*(data: Data, builder: var DOMBuilder) =
  builder.openTag(Tag.table) # table
  builder.attr(Attr.class, "table table-striped latest-data") 
  builder.openTag(Tag.tbody) # tbody
  # control flow break !!!!!!!!!!!!!!!!
  for db in data.databases:
    builder.openTag(Tag.tr) # tr           

    builder.openTag(Tag.td) # td           
    builder.attr(Attr.class, "dbname") 
    builder.textString(db.name)   # !!!!!!!!!!!!!
    builder.closeTag() # /td

    let length = db.queries.len
    builder.openTag(Tag.td) # td
    builder.attr(Attr.class, "query-count")
    builder.openTag(Tag.span) #span
    builder.attr(Attr.class, className(db)) # !!!!!!!!
    builder.textString($length)  # !!!!!!!!!!!
    builder.closeTag() # /span
    builder.closeTag() # /td

    for i in 0..4:
      if i < length:
        let query = db.queries[i]
        builder.openTag(Tag.td) # td
        builder.attr(Attr.class, className(query))
        #let s = formatFloat(query.elapsed, ffDecimal, 2)
        var s = $(query.elapsed div 100)
        s.add '.'
        s.add $(query.elapsed mod 100)
        builder.textString(s)
        builder.openTag(Tag.`div`) # div
        builder.attr(Attr.class, "popover left")
        builder.openTag(Tag.`div`) # div
        builder.attr(Attr.class, "popover-content")
        builder.textString(query.query)
        builder.closeTag() # /div
        builder.openTag(Tag.`div`) # div
        builder.attr(Attr.class, "arrow")
        builder.closeTag() # /div
        builder.closeTag() # /div
        builder.closeTag() # /td
      else:
        builder.openTag(Tag.td) # td
        builder.attr(Attr.class, "Query")
        #builder.attr(Attr.width, "40")
        builder.text(" ")
        builder.closeTag() # /td

    builder.closeTag() # /tr

  builder.closeTag() # /tbody
  builder.closeTag() # /table


when isMainModule:
  var builder = initDOMBuilder()

  import times

  const ITERS = 1000

  let start = cpuTime()

  for i in 0..<ITERS:
    builder.clear()
    let data = getData()
    data.render(builder)

  echo "Iteration time: ", formatFloat((cpuTime() - start) * 1000 / ITERS, ffDecimal, 3), " ms"

  echo builder

# var orig = initDOMBuilder()

# import diff

# var patch = initPatch()
# diff(patch, builder.root, orig.root)


