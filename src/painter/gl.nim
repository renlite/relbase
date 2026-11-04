import opengl
import pixie as px
import ../utils/renderobject
import ../utils/geometry
import ../utils/color
import std/with
import std/[os]
#import asyncdispatch
#import ../utils/atlas as silky
import silky/atlas as silky
import std/[tables, unicode] #for atlas test

const
    # rectangle
    RECTANGLE_VERTEX_SRC  = staticRead "../shader/group_rectangle.vert"
    RECTANGLE_FRAGMENT_SRC = staticRead "../shader/group_rectangle.frag"
    # glyph_atlas
    GLYPH_ATLAS_VERTEX_SRC  = staticRead "../shader/group_glyph_atlas.vert"
    GLYPH_ATLAS_FRAGMENT_SRC = staticRead "../shader/group_glyph_atlas.frag"

type
  GroupLayer = ref object
    rectanglePoints:    seq[float32]
    textPoints:         seq[float32]

  Painter* = ref object
    frame*:               Size # Window Size
    rectangleProgram:     GLuint
    glyphAtlasProgram:    GLuint
    glyphAtlasTexture:    GLuint

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
    echo shaderSource
  else:
    if shaderType == GL_VERTEX_SHADER:
      discard
    elif shaderType == GL_FRAGMENT_SHADER:
      discard
    return shader

proc createProgram(self: Painter, programName: string): GLuint =
  var
    vertexShader: GLuint
    fragmentShader: GLuint
  if programName == "rectangle":
    vertexShader = self.createShader(RECTANGLE_VERTEX_SRC, GL_VERTEX_SHADER)
    fragmentShader = self.createShader(RECTANGLE_FRAGMENT_SRC, GL_FRAGMENT_SHADER)
  elif programName == "glyphAtlas":
    vertexShader = self.createShader(GLYPH_ATLAS_VERTEX_SRC, GL_VERTEX_SHADER)
    fragmentShader = self.createShader(GLYPH_ATLAS_FRAGMENT_SRC, GL_FRAGMENT_SHADER)
  let program: GLuint = glCreateProgram()
  glAttachShader(program, vertexShader)
  glAttachShader(program, fragmentShader)
  glLinkProgram(program)
  return program
  #var logLength: GLint
  #glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength)
  #let info = glGetProgramInfoLog(program)
  #if glGetProgrami(program, GL_LINK_STATUS) == GL_FALSE:
  #    echo("failed to link OpenGL program:\n%s", info)

proc uploadGlyphAtlas*(self: Painter, image: px.Image) =
  ## Replace the GPU atlas texture from a CPU image.
  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, self.glyphAtlasTexture)

  glEnable(GL_TEXTURE2D)

  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_MIN_FILTER,
    GL_LINEAR_MIPMAP_LINEAR.GLint
  )
  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_MAG_FILTER,
    GL_LINEAR.GLint
  )
  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_WRAP_S,
    GL_CLAMP_TO_EDGE.GLint
  )
  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_WRAP_T,
    GL_CLAMP_TO_EDGE.GLint
  )

  glTexImage2D(
    GL_TEXTURE_2D,
    0,
    GL_RGB.GLint,
    image.width.GLint,
    image.height.GLint,
    0,
    GL_RGB,
    GL_UNSIGNED_BYTE,
    cast[pointer](image.data[0].addr)
  )
  glGenerateMipmap(GL_TEXTURE_2D)
  echo("glTexture OK")

proc init*(self: Painter) =
  loadExtensions() #gl
  glDisable(GL_DEPTH_TEST)
  glEnable(GL_BLEND)
  # p.logError()

  # rectangle
  self.rectangleProgram = self.createProgram("rectangle")

  # buildfont_atlas
  let builder = silky.newAtlasBuilder(1024, 4)
  builder.addDir("data/", "data/")
  builder.addFont("data/__MyFontName__.ttf", "Default", 18.0)
  builder.addFont("data/__MyFontName__.ttf", "H1", 48.0)
  builder.write("dist/glyph_atlas.png")
  # glyphAtlas

  self.glyphAtlasProgram = self.createProgram("glyphAtlas")
  glGenTextures(1, self.glyphAtlasTexture.addr)
  glActiveTexture(GL_TEXTURE0) # first (GL_TEXTURE0) of 16 or 32 Texture buffer is used for glyphAtlas
  glBindTexture(GL_TEXTURE_2D, self.glyphAtlasTexture)
  
  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_MIN_FILTER,
    GL_LINEAR_MIPMAP_LINEAR.GLint
  )
  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_MAG_FILTER,
    GL_LINEAR.GLint
  )
  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_WRAP_S,
    GL_CLAMP_TO_EDGE.GLint
  )
  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_WRAP_T,
    GL_CLAMP_TO_EDGE.GLint
  )

  glTexImage2D(
    GL_TEXTURE_2D,
    0,
    GL_RGBA8.GLint,
    builder.atlasImage.width.GLint,
    builder.atlasImage.height.GLint,
    0,
    GL_RGBA,
    GL_UNSIGNED_BYTE,
    cast[pointer](builder.atlasImage.data[0].addr)
  )
  glGenerateMipmap(GL_TEXTURE_2D)
  # self.uploadGlyphAtlas(builder.atlasImage)


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
  #   2 triangles = rect in px     NDC: Normalized Device Coordinates
  #   (P1)- - - - - (P2/P5)        (-1/1) -  - - -  - -(1/1)
  #    |           /    |            |         |         |
  #    |         /      |            |         |         |
  #    |       /        |            | - - - (0/0) - - - |
  #    |     /          |            |         |         |
  #    |   /            |            |         |         |
  #   (P3/P4) - - - - -(P6)        (-1/-1) - - - - - -(1/-1)
  #   NDC: Normalization is calculated in the shader 'group_rectangle.ver' on the GPU
  with result:
    # (P1)
    add([x1Pos, y1Pos])  #att_vert in px (not normalized)
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords
    # (P2)
    add([x2Pos, y1Pos])  #att_vert in px (not normalized)
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords
    # (P3)
    add([x1Pos, y2Pos])  #att_vert in px (not normalized)
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords
    # (P4)
    add([x1Pos, y2Pos])  #att_vert in px (not normalized)
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords
    # (P5)
    add([x2Pos, y1Pos])  #att_vert in px (not normalized)
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords
    # (P6)
    add([x2Pos, y2Pos])  #att_vert in px (not normalized)
    add([strokeWidthScaled, radiusScaled])  #att_type
    add([fillR, fillG, fillB, fillA])  #att_fill_color
    add([strokeR, strokeG, strokeB, strokeA])  #att_stroke_color
    add([x1Scaled, x2Scaled, y1Scaled, y2Scaled])  #att_rect_coords


proc calcTextCoords(self: Painter, text: Text, pos: Position): seq[float32] =
  ## Calculates coordinates for each glyph a rectangle as float32-stream for the shader
  var
    pos1 = text.position
  let
    xPosDiff = pos.x - pos1.x # + xPad
    yPosDiff = pos.y - pos1.y # + yPad
  #
  #x1Pos := pos.X - pad
  #x2Pos := pos.X + size.Width + pad
  #y1Pos := pos.Y - pad
  #y2Pos := pos.Y + size.Height + pad

  #   2 triangles = rect in px     NDC: Normalized Device Coordinates      Texture Coordinates of a glyph
  #   (P1)- - - - - (P2/P5)        (-1/1)- - - - - - -(1/1)                (0/1)- - - - - - -(1/1)
  #    |           /    |            |        |        |                     |  a b c d e f g  |
  #    |         /      |            |        |        |                     |  h i j K x y    |
  #    |       /        |            |- - - (0/0) - - -|                     |                 |
  #    |     /          |            |        |        |                     | (glypth image)  |
  #    |   /            |            |        |        |                     |                 |
  #   (P3/P4) - - - - -(P6)        (-1/-1) - - -  - -(1/-1)                (0/0)- - - - - - -(1/0)
  #   NDC: Normalization is calculated in the shader 'group_glyph_atlas.ver' on the GPU
  #   Texture Coordinates: First calculation on CPU (after working switch to GPU)
  
  let silkyAtlas = silky.readAtlasFromPng("dist/glyph_atlas.png")
  echo "AtlasSize px"
  echo silkyAtlas.size
  #let fontAtlasDefault = silkyAtlas.fonts["Default"]
  #let lhDefault = fontAtlasDefault.lineHeight
  #echo(lhDefault)
  let fontAtlasH1 = silkyAtlas.fonts["H1"]
  echo "FontSize px"
  echo fontAtlasH1.size
  echo "FontLineHeight px"
  echo(fontAtlasH1.lineHeight)
  echo "descent"
  echo(fontAtlasH1.descent)
  echo "asscent"
  echo(fontAtlasH1.ascent)
  echo "LineGap"
  echo(fontAtlasH1.lineGap)

  var 
    x1Pos, x2Pos, y1Pos, y2Pos: float32
    idx: int
    prvWidth: float32

  var 
    letter: ptr silky.LetterEntry
    runes: seq[Rune]
    tx1Pos, tx2Pos, ty1Pos, ty2Pos: float32
    tcx1Pos, tcx2Pos, tcy1Pos, tcy2Pos: float32

  x1Pos = pos1.x
  runes = toRunes(text.value)
  for rune in runes:
    idx += 1
    echo rune
    discard silky.lookupLetter(fontAtlasH1, rune, 0, letter)
    #echo(letter.x)
    #echo(letter.y)
    #echo(letter.boundsX)
    #echo(letter.boundsY)
    #echo(letter.boundsWidth)
    #echo(letter.boundsHeight)
    #echo(letter.advance)
    #echo(letter.kerning)

    if idx > 1:
      x1Pos = x1Pos + prvWidth + letter.boundsX
    x2Pos = x1Pos + letter.boundsWidth
    y2Pos = pos1.y + fontAtlasH1.ascent + (letter.boundsHeight + letter.boundsY)
    y1Pos = y2Pos - letter.boundsHeight

    # Atlas Coords
    tx1Pos = letter.x.float32
    tcx1Pos = tx1Pos / 1024.0
    # echo tx1Pos
    tx2Pos = letter.x.float32 + letter.boundsWidth
    tcx2Pos = tx2Pos / 1024.0
    # echo tx2Pos
    ty1Pos = letter.y.float32
    tcy1Pos = ty1Pos / 1024.0
    # echo ty1Pos
    ty2Pos = letter.y.float32 + letter.boundsHeight
    tcy2Pos = ty2Pos / 1024.0
    # echo ty2Pos
    # *************
    if rune == ' '.Rune:
      prvWidth = letter.advance
      continue
    else:
      prvWidth = letter.boundsWidth + letter.boundsX
    # *************
    with result:
      # (P1)
      add([x1Pos, y1Pos]) #att_vert in px (not normalized)
      # (texture x | texture y | UNUSED | UNUSED )
      add([tcx1Pos, tcy1Pos, float32(0.0), float32(0.0)]) # att_type
      # add([float32(0.0), float32(1.0), float32(0.0), float32(0.0)]) # att_type

      # (P2)
      add([x2Pos, y1Pos]) #att_vert in px (not normalized)
      # (texture x | texture y | UNUSED | UNUSED )
      add([tcx2Pos, tcy1Pos, float32(0.0), float32(0.0)]) # att_type
      # add([float32(1.0), float32(1.0), float32(0.0), float32(0.0)]) # att_type

      # (P3)
      add([x1Pos, y2Pos]) #att_vert in px (not normalized)
      # (texture x | texture y | UNUSED | UNUSED )
      add([tcx1Pos, tcy2Pos, float32(0.0), float32(0.0)]) # att_type
      # add([float32(0.0), float32(0.0), float32(0.0), float32(0.0)]) # att_type

      # (P4)
      add([x1Pos, y2Pos]) #att_vert as px (not normalized)
      # (texture x | texture y | UNUSED | UNUSED )
      add([tcx1Pos, tcy2Pos, float32(0.0), float32(0.0)]) # att_type
      # add([float32(0.0), float32(0.0), float32(0.0), float32(0.0)]) # att_type

      # (P5)
      add([x2Pos, y1Pos]) #att_vert in px (not normalized)
      # (texture x | texture y | UNUSED | UNUSED )
      add([tcx2Pos, tcy1Pos, float32(0.0), float32(0.0)]) # att_type
      # add([float32(1.0), float32(1.0), float32(0.0), float32(0.0)]) # att_type
      
      # (P6)
      add([x2Pos, y2Pos]) #att_vert in px (not normalized)
      # (texture x | texture y | UNUSED | UNUSED )
      add([tcx2Pos, tcy2Pos, float32(0.0), float32(0.0)]) # att_type
      # add([float32(1.0), float32(0.0), float32(0.0), float32(0.0)]) # att_type

proc drawRectangle*(self: Painter, rect: Rectangle, pos: Position) =
  let rectanglePoints = self.calcRectangleCoords(pos, rect)
  self.groupLayers[0].rectanglePoints.add(rectanglePoints)

proc drawText(self: Painter, text: Text, pos: Position) =
  let textPoints = self.calcTextCoords(text, pos)
  self.groupLayers[0].textPoints.add(textPoints)

proc drawObject*(self: Painter, rendObj: RenderObject, pos: Position) =
  if rendObj of Rectangle:
    self.drawRectangle(rect = (Rectangle)rendObj, pos = pos)
  elif rendObj of renderobject.Circle:
    let 
      radius = renderobject.Circle(rendObj).radius
      rect = Rectangle(id: rendObj.id,
                         size: Size(width: radius, height: radius), 
                         position: rendObj.position, 
                         strokeWidth: rendObj.strokeWidth,
                         fillColor: rendObj.fillColor,
                         strokeColor: rendObj.strokeColor,
                         cornerRadius: radius * 0.5)
    self.drawRectangle(rect = rect, pos = pos)
  elif rendObj of Text:
    self.drawText(text = (Text)rendObj, pos = pos)

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
  ## UPLOAD vertex-streams for GroupLayer to GPU
  glClearColor(0.0f, 0.0f, 0.0f, 0.0f)
  glClear(GL_COLOR_BUFFER_BIT)
  glClear(GL_DEPTH_BUFFER_BIT)
  glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
  #echo "Upload start"
  for groupLayer in self.groupLayers:
    if groupLayer.rectanglePoints.len > 0:
      echo "***** rectanglePoints.len"
      echo groupLayer.rectanglePoints.len

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
      var frameSizeUniform: GLint = glGetUniformLocation(program, "frame_size")
      var (frameWidthScaled, frameHeightScaled) = self.scaleFrameSize(self.frame)
      glUniform2f(frameSizeUniform, frameWidthScaled, frameHeightScaled)
      # TODO: ErrorLog
      # --------------------------- glDrawArrays ---------------------------------
      glDrawArrays(GL_TRIANGLES, 0, GLsizei(groupLayer.rectanglePoints.len / 16) )
      # --------------------------------------------------------------------------
      glDisableVertexAttribArray(GLuint(glGetAttribLocation(program, "att_vert")))
      glDisableVertexAttribArray(GLuint(glGetAttribLocation(program, "att_type")))
      glDisableVertexAttribArray(GLuint(glGetAttribLocation(program, "att_fill_color")))
      glDisableVertexAttribArray(GLuint(glGetAttribLocation(program, "att_stroke_color")))
      glDisableVertexAttribArray(GLuint(glGetAttribLocation(program, "att_rect_coords")))
      # TODO: ErrorLog
      freeBuffer(vbo)

    if groupLayer.textPoints.len > 0:
      echo "***** textPoints.len"
      echo groupLayer.textPoints.len
     
      var program = self.glyphAtlasProgram
      glUseProgram(program)
      var id: GLint
      glGetIntegerv(GL_CURRENT_PROGRAM, id.addr);

      glBindTexture(GL_TEXTURE_2D, self.glyphAtlasTexture)

      var vbo: uint32
      glGenBuffers(1, vbo.addr)
      glBindBuffer(GL_ARRAY_BUFFER, vbo)
      glBufferData(GL_ARRAY_BUFFER, groupLayer.textPoints.len*4, groupLayer.textPoints[0].addr, GL_STATIC_DRAW)

      # BEG: Windy needs this section
      var vao: uint32
      glGenVertexArrays(1, vao.addr);
      glBindVertexArray(vao);
      # END:
      
      self.defineVertexAttribute(program, "att_vert", 2, 6, 0)
      self.defineVertexAttribute(program, "att_type", 4, 6, 2)

      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      # TODO: ErrorLog
      var frameSizeUniform: GLint = glGetUniformLocation(program, "frame_size")
      var (frameWidthScaled, frameHeightScaled) = self.scaleFrameSize(self.frame)
      glUniform2f(frameSizeUniform, frameWidthScaled, frameHeightScaled)
      echo self.glyphAtlasTexture
      var glyphAtlasTextureUniform: GLint = glGetUniformLocation(program, "glyp_atlas_texture")
      glUniform1i(glyphAtlasTextureUniform, GLint(self.glyphAtlasTexture - 1))
      # TODO: ErrorLog
      # --------------------------- glDrawArrays ---------------------------------
      glDrawArrays(GL_TRIANGLES, 0, GLsizei(groupLayer.textPoints.len / 6) )
      # --------------------------------------------------------------------------
      # TODO: ErrorLog
      freeBuffer(vbo)

    #// delete
    #p.textures = nil
    #p.groupLayers[idx].roundRectPoints = nil
    #p.groupLayers[idx].linePoints = nil
    #p.groupLayers[idx].texturePoints = nil


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