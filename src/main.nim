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
                            cornerRadius:   20.0,
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

  t1 = Text(id: "T1",
                    # size:       Size(width: 120, height: 80),  #shout be calculated from font and value later
                    position:   Position(x: 210, y: 200), 
                    fontName:   "Ubuntu",
                    fontSize:   14,
                    value:      "{Hello} OpenGL" )

    
  btn1r = Rectangle(id: "BTN1R",
                            size:           Size(width: 260, height: 80), 
                            position:       Position(x: 800, y: 200), 
                            strokeWidth:    4.0,
                            cornerRadius:   20.0,
                            fillColor:      nrgba(0, 50, 200, 150), 
                            strokeColor:    nrgba(200, 150, 0, 255))

  btn1t = Text(id: "BTN1T",
                    # size:       Size(width: 120, height: 80),  #shout be calculated from font and value later
                    position:   Position(x: 890, y: 205), 
                    fontName:   "Ubuntu",
                    fontSize:   14,
                    value:      "Nim" )


  btn2r = Rectangle(id: "BTN2R",
                            size:           Size(width: 260, height: 80), 
                            position:       Position(x: 800, y: 300), 
                            strokeWidth:    4.0,
                            cornerRadius:   20.0,
                            fillColor:      nrgba(0, 50, 200, 150), 
                            strokeColor:    nrgba(200, 150, 0, 255))

  btn2t = Text(id: "BTN2T",
                    # size:       Size(width: 120, height: 80),  #shout be calculated from font and value later
                    position:   Position(x: 860, y: 305), 
                    fontName:   "Ubuntu",
                    fontSize:   14,
                    value:      "Python" )

  btn3r = Rectangle(id: "BTN3R",
                            size:           Size(width: 260, height: 80), 
                            position:       Position(x: 800, y: 400), 
                            strokeWidth:    4.0,
                            cornerRadius:   20.0,
                            fillColor:      nrgba(0, 50, 200, 150), 
                            strokeColor:    nrgba(200, 150, 0, 255))

  btn3t = Text(id: "BTN3T",
                    # size:       Size(width: 120, height: 80),  #shout be calculated from font and value later
                    position:   Position(x: 865, y: 405), 
                    fontName:   "Ubuntu",
                    fontSize:   14,
                    value:      "Kotlin" )

  btn4r = Rectangle(id: "BTN4R",
                            size:           Size(width: 260, height: 80), 
                            position:       Position(x: 800, y: 500), 
                            strokeWidth:    4.0,
                            cornerRadius:   20.0,
                            fillColor:      nrgba(0, 50, 200, 150), 
                            strokeColor:    nrgba(200, 150, 0, 255))
  btn4t = Text(id: "BTN4T",
                    # size:       Size(width: 120, height: 80),  #shout be calculated from font and value later
                    position:   Position(x: 865, y: 505), 
                    fontName:   "Ubuntu",
                    fontSize:   14,
                    value:      "C/C++" )

                      
myApp.renderObjects.add(r1)
myApp.renderObjects.add(r2)
myApp.renderObjects.add(r3)
myApp.renderObjects.add(c1)
myApp.renderObjects.add(c2)
myApp.renderObjects.add(t1)
# Buttons 
myApp.renderObjects.add(btn1r)
myApp.renderObjects.add(btn1t)
myApp.renderObjects.add(btn2r)
myApp.renderObjects.add(btn2t)
myApp.renderObjects.add(btn3r)
myApp.renderObjects.add(btn3t)
myApp.renderObjects.add(btn4r)
myApp.renderObjects.add(btn4t)

myApp.runApp()