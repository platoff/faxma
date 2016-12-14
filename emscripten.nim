
type 
  EmscriptenMainLoop = proc() {.cdecl.}
  

proc emscripten_set_main_loop*(
  callback: EmscriptenMainLoop, fps: int, simulate_infinite_loop: int) {.header: "<emscripten/emscripten.h>", importc.}
