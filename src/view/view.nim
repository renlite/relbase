import std/[os]
import ../utils/geometry
import ../utils/renderobject

when defined(GlfwGL):
  import window_glfw as x
  import ../painter/gl
  const WINDRIVER = "GLFW"
elif defined(WindyGL):
  import window_windy as x
  import ../painter/gl
  const WINDRIVER = "Windy"


type
  View* = ref object
    winDriver:   string
    viewport:    x.Win
    paintDriver: string
    painter:     Painter


var view*: View

proc newView*(frame: Size, pixScale: float32): View =
  view = View(winDriver: WINDRIVER,
              paintDriver: "GL")
  view.viewport = x.createWin(frame)
  view.painter = newPainter(frame, 1.0)
  result = view

proc renderTree*(self: View, renderObjects: seq[RenderObject]) =
  self.painter.renderTree(renderObjects)
  self.viewport.swapBuffers()

# --- BEG: Events ---
proc windowResized*(frame: Size) =
  view.painter.frame = frame
  view.renderTree(renderObjects = @[])

proc buttonPressed*(pos: Position) =
  echo pos

proc registerResize(self: View, callback: proc(frame: Size)) =
  self.viewport.setWindowResizedCallback(callback)

proc registerButtonPressed(self: View, callback: proc(pos: Position)) =
  self.viewport.setButtonPressedCallback(callback)
# --- END: Events ---

proc init*(self: View) =
  ## Initialization
  self.viewport.setWindowResizedCallback(windowResized)
  self.viewport.setButtonPressedCallback(buttonPressed)
  self.viewport.makeContextCurrent()
  self.painter.init()

proc display*(self: View, renderObjects: seq[RenderObject]) =
  ## MAIN-LOOP
  self.renderTree(renderObjects = renderObjects)
  while not x.reqWinClose(self.viewport):
    #let winSize = getWinSize(self.window)
    #if self.frame.width != winSize.w.float32 or self.frame.height != winSize.h.float32: 
    #  self.frame = Size(width: winSize.w.float32, height: winSize.h.float32)
    #  let b = self.renderTree(renderObjects = renderObjects)
    #  echo "Upload called ..."  
    x.pollEvents()
    sleep(100) #60 FPS