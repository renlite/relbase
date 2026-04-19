import view/view
import utils/geometry
import utils/renderobject
export renderobject

type 
  App* = object
    id: string
    icon: string
    view: View
    #for tests, later RenderObject(Interface/Closures)
    renderObjects*: seq[RenderObject] 

proc newApp*(id: string = "app001"): App =
  result = App()
  result.id = id

proc initApp*(self: var App) =
  self.view = newView(frame = Size(width: 1280.float32, height: 800.float32), pixScale = 1.0)
  self.view.init()

proc runApp*(self: App) =
  ## Starts the App - Does not return
  self.view.display(renderObjects = self.renderObjects)



## Define App-Callbacks
