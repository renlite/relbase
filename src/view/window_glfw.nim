import nglfw as w
export w
import ../utils/renderobject
import ../utils/geometry
import ../utils/color

type Win* = w.Window


var
  callWindowResized: seq[proc(frame: Size)]
  callButtonPressed: seq[proc(pos: Position)]

proc reqWinClose*(window: w.Window): bool =
  result = w.windowShouldClose(window)

proc createWin*(frame: Size): w.Window =
  if not w.init():
    raise newException(Exception, "Failed to Initialize GLFW")
  result = w.createWindow(frame.width.cint, frame.height.cint, "GLFW3", nil, nil)

proc getWinSize*(window: w.Window): tuple[w,h: int] =
  var width, height: cint
  w.getWindowSize(window, width.addr, height.addr)
  result = (width.int, height.int)

# --- WindowResize ---
proc windowResized(window: w.Window) {.cdecl.} =
  let winSize = window.getWinSize()
  let frame = Size(width: winSize.w.float32, height: winSize.h.float32)
  for call in callWindowResized:
    call(frame)

proc setWindowResizedCallback*(window: w.Window, callback: proc(frame: Size)) =
  discard setWindowRefreshCallback(window, windowResized)
  callWindowResized.add(callback)

# --- ButtonPressed ---
proc buttonPressed(window: w.Window, button, action, mods: cint) {.cdecl.} =
  var xpos, ypos: cdouble
  window.getCursorPos(xpos.addr, ypos.addr)
  let pos = Position(x: xpos.float32, y: ypos.float32)
  for call in callButtonPressed:
    call(pos)

proc setButtonPressedCallback*(window: w.Window, callback: proc(pos: Position)) =
  discard setMouseButtonCallback(window, buttonPressed)
  callButtonPressed.add(callback)

    