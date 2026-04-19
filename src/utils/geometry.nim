import std/math

type
    Position* = object
        x*: float32
        y*: float32
    
    Size* = object
        width*: float32
        height*: float32


proc roundToPixel*(x: float32, pixScale: float32): float32 =
  # in fyne:gl/draw.go
  if pixScale == 1.0:
    return round(x)
  result = round(x * pixScale) / pixScale