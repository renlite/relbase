import geometry
import color

type
  RenderObject* = ref object of RootObj
    id*: string
    position*: Position
    fillColor*: NRGBA
    strokeColor*: NRGBA = NRGBA(r: 0, g: 0, b: 0, a: 0)  # default: transparent
    strokeWidth*: float32
    hidden*: bool

  Rectangle* = ref object of RenderObject
    size*: Size
    minSize*: Size
    cornerRadius*: float32

  Circle* = ref object of RenderObject
    radius*: float32
    minRadius*: float32





#var renderObjects: seq[RenderObject] 

#let roCircle = Circle(id: "C1",
#                            position:       Position(x: 450, y: 400), 
#                            strokeWidth:    5.0,
#                            fillColor:      nrgba(0, 17, 200, 150),
#                            strokeColor:    nrgba(100, 120, 10, 255),
#                            radius:         100)
#renderObjects.add(roCircle)