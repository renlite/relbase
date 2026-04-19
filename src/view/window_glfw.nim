import nglfw as w
export w
import ../utils/renderobject
import ../utils/geometry
import ../utils/color

type Win* = w.Window

var callOnResize: proc(frame: Size)

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

proc resizeCallback*(window: w.Window) {.cdecl.} =
  let winSize = window.getWinSize()
  let frame = Size(width: winSize.w.float32, height: winSize.h.float32)
  callOnResize(frame)

proc setResizeCallback*(window: w.Window, forwardResize: proc(frame: Size)) =
  let fn = setWindowRefreshCallback(window, resizeCallback)
  callOnResize = forwardResize




    