import windy as w
export w
import ../utils/renderobject
import ../utils/geometry
import ../utils/color

type Win* = w.Window

var
  win: w.Window
  callWindowResized: seq[proc(frame: Size)]
  callButtonPressed: seq[proc(pos: Position)]

proc reqWinClose*(window: w.Window): bool =
  result = window.closeRequested

proc createWin*(frame: Size): w.Window =
  result = w.newWindow("Windy", ivec2(frame.width.cint, frame.height.cint))

proc getWinSize*(window: w.Window): tuple[w,h: int] =
  result = (window.size.x, window.size.y)

proc getMousePos*(window: w.Window): tuple[x,y: int] =
  result = (window.mousePos.x, window.mousePos.y)

# --- WindowResize ---
proc windowResized() =
  let winSize = win.getWinSize()
  let frame = Size(width: winSize.w.float32, height: winSize.h.float32)
  for call in callWindowResized:
    call(frame)

proc setWindowResizedCallback*(window: w.Window, callback: proc(frame: Size)) =
  window.onResize = windowResized
  win = window
  callWindowResized.add(callback)

# --- ButtonPressed ---
proc buttonPressed*(button: w.Button) =
  let (xpos, ypos) = win.getMousePos()
  let pos = Position(x: xpos.float32, y: ypos.float32)
  for call in callButtonPressed:
    call(pos)

proc setButtonPressedCallback*(window: w.Window, callback: proc(pos: Position)) =
  window.onButtonPress = buttonPressed
  callButtonPressed.add(callback)