
proc JSrender(p: pointer) {.importc.}

import dbmonster, dom, strutils

var builder = initDOMBuilder()

let data = getData()
data.render(builder)

builder.done()

echo builder.current.kids[0]

JSrender(builder.current.kids[0])
