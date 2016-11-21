
mergeInto(LibraryManager.library, {

  $renderElement: function (p, level) {

    function space(num) {
      return new Array(num + 1).join(" ");
    }

      p = p | 0;
      var tags = [
        "DOCUMENT_ROOT", "TEXT", "a", "button", "div", "h1", "header", "hr", "input",
        "label", "li", "p", "section", "span", "table", "tbody", "td", "tr", "ul"
      ];

      if (level > 7) return;

      var t = HEAP32[((p)>>2)];
      // if (t == 1) {
      //   //return createTextNode()
      //   //console.log(Pointer_stringify(HEAP32[((p + 12)>>2)]));
      //   console.log("text");
      // } else {
        var kids = HEAP32[((p + 4)>>2)]
        var attrs = HEAP32[((p + 8)>>2)]
        console.log(space(level*2)," tag: ", tags[t], " kids: ", kids, " attrs: ", attrs);
        p += 12 + (attrs * 8);
        for (var i=0; i<kids; i++) {
          var kidp = HEAP32[((p)>>2)];          
          //console.log("kid tag: ", tags[HEAP32[((kidp)>>2)]])
          renderElement(kidp, level + 1);
          p += 4;
        }
//      }
  },

  JSrender: function(p) {
    p = p | 0;
    console.log("Hello from emscripten: ", HEAP32[((p)>>2)]);
    renderElement(p, 0);          
  },
  JSrender__deps: ["$renderElement"],
})

 