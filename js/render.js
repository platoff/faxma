
mergeInto(LibraryManager.library, {

  $attributeNames: ["TEXT", "class", "for", "placeholder", "type", "value", "width", "title"],

  $tags: [
    "DOCUMENT_ROOT", "TEXT", "a", "button", "div", "h1", "header", "hr", "input",
    "label", "li", "p", "section", "span", "table", "tbody", "td", "tr", "ul"
  ],

  $renderElement: function (p) {
    p = p | 0;

    var t = HEAP32[((p)>>2)];
    p += 4;
    var kids = HEAP32[((p)>>2)];
    p += 4;
    var attrs = HEAP32[((p)>>2)];
    p += 4;

    var e;
    switch(t) {
      case 0:
        console.log("render DOCUMENT_ROOT");
        e = createTextNode("error: DOCUMENT ROOT HERE");
        break;
      case 1:
        p += 4; //attrid == text
        var text = AsciiToString(HEAP32[((p)>>2)]);
        e = document.createTextNode(text);
        p += 4;
        break;
      default:
        e = document.createElement(tags[t]);
        for (var i=0; i<attrs; i++) {
          var a = HEAP32[((p)>>2)];
          p += 4;
          var v = HEAP32[((p)>>2)];
          p += 4;
          var value = AsciiToString(v);
          e.setAttribute(attributeNames[a], value);
        }
        for (var i=0; i<kids; i++) {
          var kid = HEAP32[((p)>>2)];
          p += 4;
          var re = renderElement(kid);
          e.appendChild(re);
        }
    }
    return e;
  },
  $renderElement__deps: ["$attributeNames", "$tags"],  

  JSrender: function(p) {
    p = p | 0;
    var element = document.getElementById("app");
    //console.log("RENDER: ", p);
    // p is PATCH address
    while(true) {
      var cmd = HEAP32[((p)>>2)] | 0;
      //console.log("cmd: ", cmd);
      p += 4;
      switch(cmd) {
        case 0: // HALT
          return;
        case 1: // NAV_UP
          var times = HEAP32[((p)>>2)] | 0;
          p += 4;
          for(var i=0;i<times;i++)
            element = element.parentNode;
          break;
        case 2: // NAV_KID
          var nkid = HEAP32[((p)>>2)] | 0;
          p += 4;
          element = element.children[nkid];
          break;
        case 3: // NAV_PARENT
          element = element.parentNode;
          break;
        case 4: // NAV_GRAND_PARENT
          element = element.parentNode.parentNode;
          break;
        case 5: // NAV_FIRST_CHILD
          element = element.firstChild;
          break;
        case 6: // NAV_SECOND_CHILD
          element = element.firstChild.nextSibling;
          break;
        case 7: // NAV_NEXT_SIBLING
          element = element.nextSibling;
          break;
        case 8: // APPEND
          var e = HEAP32[((p)>>2)] | 0;
          p += 4;          
          element.appendChild(renderElement(e));
          break;
        case 9: // REMOVE_LAST
          element.removeChild(element.lastChild);
          break;
        case 10: // REMOVE_LAST_MANY
          var times = HEAP32[((p)>>2)] | 0;
          p += 4;   
          for(var i=0;i<times;i++)
            element.removeChild(element.lastChild);
          break;
        case 11: // ATTR_SET
          var attr = HEAP32[((p)>>2)] | 0;
          p += 4;   
          var value = AsciiToString(HEAP32[((p)>>2)]);
          p += 4;
          if(attr == 0) {
            //console.log("current value: ", element.nodeValue);
            //console.log("text: ", value);
            element.nodeValue = value;
          } else {
            element.setAttribute(attributeNames[attr], value);
          }
          break;
        case 12: // ATTR_REMOVE
          var attr = HEAP32[((p)>>2)] | 0;
          p += 4;   
          element.removeAttribute(attributeNames[attr]);
          break;
        default:
          console.log("SHIT HAPPENS");
          return;
      }
    }
  },
  JSrender__deps: ["$attributeNames", "$renderElement"],
})

 