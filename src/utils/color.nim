
type
  NRGBA* = object
    ## NRGBA represents a non-alpha-premultiplied 32-bit color.
    r*: uint8 
    g*: uint8 
    b*: uint8 
    a*: uint8

  RGBA* = object
    ## RGBA represents a alpha-premultiplied float32 color.
    r*: float32
    g*: float32
    b*: float32
    a*: float32

proc nrgba*(r, g, b, a: uint8): NRGBA {.inline.} =
  ## Creates from uint8s like:
  ## * rgba(255,0,0,255) -> red
  ## * rgba(0,255,0,255) -> green
  ## * rgba(0,0,255,255) -> blue
  ## * rgba(0,0,0,255)   -> opaque  black
  ## * rgba(0,0,0,0)   -> transparent black
  NRGBA(r: r, g: g, b: b, a: a)

proc rgba*(c: NRGBA): RGBA {.inline.} =
  ## Convert NRGBA to RGBA
  if c.a == 0:
    return RGBA(r: 0, g: 0, b: 0, a: 0)
  var alpha = float32(c.a)
  result.r = float32(c.r) / alpha
  result.g = float32(c.g) / alpha
  result.b = float32(c.b) / alpha
  result.a = float32(c.a) / 255

proc fragmentRGBA*(c: NRGBA): (float32, float32, float32, float32) =
  ## fragmentRGBA represents a alpha-premultiplied float32 color for GL
  let col: RGBA = rgba(c)
  result = (col.r, col.g, col.b, col.a)


# https://nim-lang.github.io/Nim/tut1.html#basic-types-integers
# int int8 int16 int32 int64 uint uint8 uint16 uint32 uint64