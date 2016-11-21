
type
  Tag* {.pure.} = enum
    DOCUMENT_ROOT
    TEXT
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
    TEXT
    class,
    `for`,
    placeholder,
    `type`,
    value,
    width
    title
