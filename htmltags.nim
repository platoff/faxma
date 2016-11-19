
type
  Tag* {.pure.} = enum
    a,
    button,
    `div`,
    h1, header, hr,
    input,
    label, li
    p,
    section, span,
    table, tbody, td, tr,
    ul
    
  Attr* {.pure.} = enum
    class,
    `for`,
    placeholder,
    `type`,
    value,
    width
    title
