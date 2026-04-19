import app
import utils/color
import utils/geometry

var myApp = newApp()
myApp.initApp()


#myApp.roTree.add([RenderObject(kind: TCircle, id: "Four",
#                            position:       Position(x: 300, y: 100), 
#                            radius:         250,
#                            strokeWidth:    3.0,
#                            fillColor:      nrgba(050, 17, 200, 150),
#                            strokeColor:    nrgba(50, 250, 50, 255)
#                            )])


let 
  r1 = Rectangle(id: "R1",
                            size:           Size(width: 150, height: 200), 
                            position:       Position(x: 450, y: 400), 
                            strokeWidth:    5.0,
                            cornerRadius:   0.0,
                            fillColor:      nrgba(0, 17, 200, 150),
                            strokeColor:    nrgba(100, 120, 10, 255) )
  r2 = Rectangle(id: "R2",
                            size:           Size(width: 300, height: 400), 
                            position:       Position(x: 100, y: 50), 
                            fillColor:      nrgba(20, 200, 10, 255),
                            strokeWidth:    10.0,
                            cornerRadius:   40.0,
                            strokeColor:    nrgba(255, 120, 10, 255) )
  r3 = Rectangle(id: "R3",
                            size:           Size(width: 500, height: 300), 
                            position:       Position(x: 200, y: 200), 
                            strokeWidth:    1.0,
                            cornerRadius:   50.0,
                            fillColor:      nrgba(255, 0, 0, 150) )

  c1 = Circle(id: "C1",
                      position:       Position(x: 450, y: 400), 
                      strokeWidth:    5.0,
                      fillColor:      nrgba(0, 17, 200, 150),
                      strokeColor:    nrgba(100, 120, 10, 255),
                      radius:         100 )
  c2 = Circle(id: "C2",
                      position:       Position(x: 300, y: 100), 
                      radius:         250,
                      strokeWidth:    3.0,
                      fillColor:      nrgba(050, 17, 200, 150),
                      strokeColor:    nrgba(50, 250, 50, 255) )

                      
myApp.renderObjects.add(r1)
myApp.renderObjects.add(r2)
myApp.renderObjects.add(r3)
myApp.renderObjects.add(c1)
myApp.renderObjects.add(c2)

myApp.runApp()