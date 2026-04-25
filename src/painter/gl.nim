import opengl
import ../utils/renderobject
import ../utils/geometry
import ../utils/color
import std/with
import std/[os]
#import asyncdispatch

const
    RECTANGLE_VERTEX_SRC  = staticRead "../shader/group_rectangle.vert"
    RECTANGLE_FRAGMENT_SRC = staticRead "../shader/group_rectangle.frag"

type
  GroupLayer = ref object
    rectanglePoints:       seq[float32]
    texturePoints:         seq[float32]

  Painter* = ref object
    frame*:               Size # Window Size
    rectangleProgram:     GLuint
    textureProgram:       GLuint
    texScale:             float32
    pixScale:             float32 # pre-calculate scale*texScale for each draw
    groupLayers:          seq[GroupLayer]

proc newPainter*(frame: Size, pixScale: float32): Painter =
  result = Painter(frame: frame,
                   pixScale: pixScale)
  result.groupLayers.add(GroupLayer())

proc scaleRectangleCoords(self: Painter, x1, x2, y1, y2: float32): (float32, float32, float32, float32) =
  ## Returns scaled RectangleCoords(x1,x2,y1,y2) in same order
  let
    x1Scaled = roundToPixel(x1 * self.pixScale, 1.0)
    x2Scaled = roundToPixel(x2 * self.pixScale, 1.0)
    y1Scaled = roundToPixel(y1 * self.pixScale, 1.0)
    y2Scaled = roundToPixel(y2 * self.pixScale, 1.0)
  return (x1Scaled, x2Scaled, y1Scaled, y2Scaled)

proc scaleFrameSize(self: Painter, frame: Size): (float32, float32) =
  let
    frameWidthScaled  = roundToPixel(frame.width  * self.pixScale, 1.0)
    frameHeightScaled = roundToPixel(frame.height * self.pixScale, 1.0)
  return (frameWidthScaled, frameHeightScaled)

proc createShader(self: Painter, shaderSource: string, shaderType: GLenum): GLuint =
  var compiled: GLint = 0
  let 
    shaderCstringArr = allocCStringArray([shaderSource])
    # shaderCstringArr: array[1, string] = shaderSource  
    shader: GLuint = glCreateShader(shaderType)
  glShaderSource(shader, 1, shaderCstringArr, nil)
  glCompileShader(shader)
  glGetShaderiv(shader, GL_COMPILE_STATUS, compiled.addr)
  if compiled == 0:
    echo "Shader error"
  else:
    if shaderType == GL_VERTEX_SHADER:
      discard
    elif shaderType == GL_FRAGMENT_SHADER:
      discard
    return shader

proc createProgram(self: Painter, programName: string): GLuint =
  let
    vertexShader = self.createShader(RECTANGLE_VERTEX_SRC, GL_VERTEX_SHADER)
    fragmentShader = self.createShader(RECTANGLE_FRAGMENT_SRC, GL_FRAGMENT_SHADER)
    program: GLuint = glCreateProgram()
  glAttachShader(program, vertexShader)
  glAttachShader(program, fragmentShader)
  glLinkProgram(program)
  return program
  #var logLength: GLint
  #glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength)
  #let info = glGetProgramInfoLog(program)
  #if glGetProgrami(program, GL_LINK_STATUS) == GL_FALSE:
  #    echo("failed to link OpenGL program:\n%s", info)

proc init*(self: Painter) =
  loadExtensions() #gl
  glDisable(GL_DEPTH_TEST)
  glEnable(GL_BLEND)
  # p.logError()
  self.rectangleProgram = self.createProgram("rectangle")

proc calcRectangleCoords(self: Painter, pos: Position, rect: Rectangle): seq[float32] =
  ## Calculates coordinates of one Rectangle as float32-stream for the shader
  # coordinates:
  var
    size = rect.size
    pos1 = rect.position
  let
    xPosDiff = pos.x - pos1.x # + xPad
    yPosDiff = pos.y - pos1.y # + yPad
  #pos1.x = roundToPixel(pos1.x+xPosDiff, self.pixScale)
  #pos1.y = roundToPixel(pos1.y+yPosDiff, self.pixScale)
  #size.width = roundToPixel(size.width, self.pixScale)
  #size.height = roundToPixel(size.height, self.pixScale)
  let
    x1Pos = pos1.x
    x2Pos = (pos1.x + size.width)
    y1Pos = pos1.y
    y2Pos = (pos1.y + size.height)
  # constants: stroke/radius/colors
  let
    strokeWidthScaled = roundToPixel(rect.strokeWidth * self.pixScale, 1.0)
    radiusScaled = roundToPixel(rect.cornerRadius * self.pixScale, 1.0)
  let (fillR, fillG, fillB, fillA) = fragmentRGBA(rect.fillColor)
  var strokeNRGBA = rect.strokeColor
  #if strokeNRGBA == nil:
  #  strokeNRGBA = nrgba(0,0,0,0) # Transparent
  let (strokeR, strokeG, strokeB, strokeA) = fragmentRGBA(strokeNRGBA)
  let (x1Scaled, x2Scaled, y1Scaled, y2Scaled) = self.scaleRectangleCoords(x1Pos, x2Pos, y1Pos, y2Pos)
  #   2 triangles = rect:
  #   (P1)- - - - - (P2/P5)
  #    |           /    |
  #    |         /      |
  #    |       /        |
  #    |     /          |
  #    |   /            |
  #   (P3/P4) - - - - -(P6)
  with result:
    # (P1)
    add([x1Pos, y1Pos])  #att_vert
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords
    # (P2)
    add([x2Pos, y1Pos])  #att_vert
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords
    # (P3)
    add([x1Pos, y2Pos])  #att_vert
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords
    # (P4)
    add([x1Pos, y2Pos])  #att_vert
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords
    # (P5)
    add([x2Pos, y1Pos])  #att_vert
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords
    # (P6)
    add([x2Pos, y2Pos])  #att_vert
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords


proc drawRectangle*(self: Painter, rect: Rectangle, pos: Position) =
  let rectanglePoints = self.calcRectangleCoords(pos, rect)
  self.groupLayers[0].rectanglePoints.add(rectanglePoints)

proc drawObject*(self: Painter, rendObj: RenderObject, pos: Position) =
  if rendObj of Rectangle:
    self.drawRectangle(rect = (Rectangle)rendObj, pos = pos)
  elif rendObj of Circle:
      let 
        radius = Circle(rendObj).radius
        rect = Rectangle(id: rendObj.id,
                         size: Size(width: radius, height: radius), 
                         position: rendObj.position, 
                         strokeWidth: rendObj.strokeWidth,
                         fillColor: rendObj.fillColor,
                         strokeColor: rendObj.strokeColor,
                         cornerRadius: radius * 0.5)
      self.drawRectangle(rect = rect, pos = pos)  
  #case rendObj.kind
  #  of TRectangle:
  #    let rect = Rectangle(id: rendObj.id,
  #                       size: rendObj.size, 
  #                       position: rendObj.position, 
  #                       strokeWidth: rendObj.strokeWidth,
  #                       fillColor: rendObj.fillColor,
  #                       strokeColor: rendObj.strokeColor,
  #                       cornerRadius: rendObj.cornerRadius)
  #    self.drawRectangle(rect = rect, pos = pos)
  #  of TCircle:
  #    let rect = Rectangle(id: rendObj.id,
  #                       size: Size(width: rendObj.radius, height: rendObj.radius), 
  #                       position: rendObj.position, 
  #                       strokeWidth: rendObj.strokeWidth,
  #                       fillColor: rendObj.fillColor,
  #                       strokeColor: rendObj.strokeColor,
  #                       cornerRadius: rendObj.radius * 0.5)
  #    self.drawRectangle(rect = rect, pos = pos)  


proc defineVertexAttribute(self: Painter, program: GLuint, name: cstring, size, stride, offset: GLint) =
  let attr: GLuint = GLuint(glGetAttribLocation(program, name))
  glVertexAttribPointer(attr, size, cGL_FLOAT, GL_FALSE, stride*4, cast[pointer](offset*4))
  glEnableVertexAttribArray(attr)
  # TODO: ErrorLog

proc freeBuffer(vbo: GLuint) =
  # glBindBuffer(GL_ARRAY_BUFFER, ???GL_NO_BUFFER)
  # TODO: ErrorLog
  glDeleteBuffers(1, vbo.addr)
  # TODO: ErrorLog

proc drawGroupLayers*(self: Painter) =
  ## UPLOAD vertecex-streams for GroupLayer to GPU
  glClearColor(0.0f, 0.0f, 0.0f, 0.0f)
  glClear(GL_COLOR_BUFFER_BIT)
  glClear(GL_DEPTH_BUFFER_BIT)
  glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
  #echo "Upload start"
  for groupLayer in self.groupLayers:
    if groupLayer.rectanglePoints.len > 0:
      #echo groupLayer.rectanglePoints.len

      var program = self.rectangleProgram
      glUseProgram(program)
      var id: GLint
      glGetIntegerv(GL_CURRENT_PROGRAM, id.addr);

      var vbo: uint32
      glGenBuffers(1, vbo.addr)
      glBindBuffer(GL_ARRAY_BUFFER, vbo)
      glBufferData(GL_ARRAY_BUFFER, groupLayer.rectanglePoints.len*4, groupLayer.rectanglePoints[0].addr, GL_STATIC_DRAW)

      # BEG: Windy needs this section
      var vao: uint32
      glGenVertexArrays(1, vao.addr);
      glBindVertexArray(vao);
      # END:

      self.defineVertexAttribute(program, "att_vert", 2, 16, 0)
      self.defineVertexAttribute(program, "att_type", 2, 16, 2)
      self.defineVertexAttribute(program, "att_fill_color", 4, 16, 4)
      self.defineVertexAttribute(program, "att_stroke_color", 4, 16, 8)
      self.defineVertexAttribute(program, "att_rect_coords", 4, 16, 12)


      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      # TODO: ErrorLog
      let 
        frameSizeUniform: GLint = glGetUniformLocation(program, "frame_size")
        (frameWidthScaled, frameHeightScaled) = self.scaleFrameSize(self.frame)
      glUniform2f(frameSizeUniform, frameWidthScaled, frameHeightScaled)
      # TODO: ErrorLog
      # --------------------------- glDrawArrays ---------------------------------
      glDrawArrays(GL_TRIANGLES, 0, GLsizei(groupLayer.rectanglePoints.len / 16) )
      # --------------------------------------------------------------------------
      glDisableVertexAttribArray(GLuint(glGetAttribLocation(program, "att_fill_color")))
      glDisableVertexAttribArray(GLuint(glGetAttribLocation(program, "att_stroke_color")))
      glDisableVertexAttribArray(GLuint(glGetAttribLocation(program, "att_rect_coords")))
      # TODO: ErrorLog
      freeBuffer(vbo)

    #// delete
    #p.textures = nil
    #p.groupLayers[idx].roundRectPoints = nil
    #p.groupLayers[idx].linePoints = nil
    #p.groupLayers[idx].texturePoints = nil
  # for

#p.textrureIdx = 0

proc renderTree*(self: Painter, roTree: seq[RenderObject]) =
  if self.groupLayers[0].rectanglePoints.len == 0:
    #echo "ROStream is 0"
    for ro in roTree:
      echo ro.id
      self.drawObject(rendObj = ro, pos = Position(x: 4.0, y: 4.0))
  self.drawGroupLayers()










# Implemented in -> defineVertexAttribute(program, "att_vert", 2, 16, 0)
#let att_vert: GLuint = GLuint(glGetAttribLocation(program, "att_vert"))
#glVertexAttribPointer(att_vert, 2, cGL_FLOAT, GL_FALSE, 16*4, nil)
#glEnableVertexAttribArray(att_vert)

#let att_type: GLuint = GLuint(glGetAttribLocation(program, "att_type"))
#glVertexAttribPointer(att_type, 2, cGL_FLOAT, GL_FALSE, 16*4, cast[pointer](2*4))
#glEnableVertexAttribArray(att_type)

#let att_fill_color: GLuint = GLuint(glGetAttribLocation(program, "att_fill_color"))
#glVertexAttribPointer(att_fill_color, 4, cGL_FLOAT, GL_FALSE, 16*4, cast[pointer](4*4))
#glEnableVertexAttribArray(att_fill_color)

#let att_stroke_color: GLuint = GLuint(glGetAttribLocation(program, "att_stroke_color"))
#glVertexAttribPointer(att_stroke_color, 4, cGL_FLOAT, GL_FALSE, 16*4, cast[pointer](8*4))
#glEnableVertexAttribArray(att_stroke_color)

#let att_rect_coords: GLuint = GLuint(glGetAttribLocation(program, "att_rect_coords"))
#glVertexAttribPointer(att_rect_coords, 4, cGL_FLOAT, GL_FALSE, 16*4, cast[pointer](12*4))
#glEnableVertexAttribArray(att_rect_coords)