n = NetAddr("localhost",1239)

n.sendMsg("/background","NONE")
n.sendMsg("/background","ECLIPSE")
n.sendMsg("/background","FUJI")
n.sendMsg("/background","MONJORI")
n.sendMsg("/background","NEBULA")
n.sendMsg("/background","REFRACTION_PATTERN")
n.sendMsg("/background","DEFORM")
n.sendMsg("/background","FRACTAL_PYRAMID")

// heavy ones
n.sendMsg("/background","COLDFLAME")
n.sendMsg("/background","WATER")
n.sendMsg("/background","OCTAGRAMS")
n.sendMsg("/background","ONEWARP")
n.sendMsg("/background","PROTEAN_CLOUDS")

n.sendMsg("/background/color", 255,150,150)
n.sendMsg("/background/color", 0,125,0)
n.sendMsg("/background/color", 0,0,216)
n.sendMsg("/background/color", 125,0,0)
n.sendMsg("/background/color", 0.5,0.5,0.0)
n.sendMsg("/background/color", 0,0,0)

n.sendMsg("/state/load", "eclipse.json")
n.sendMsg("/animation/time", 1000)

n.sendMsg("/cubes/visible", true)
n.sendMsg("/cubes/visible", false)

n.sendMsg("/cubes/rotation/speed/base", 10)
n.sendMsg("/cubes/rotation/speed/base", 100)

n.sendMsg("/cubes/rotation/speed/offset", 10)
n.sendMsg("/cubes/rotation/speed/offset", 30)

n.sendMsg("/cubes/rotation/reset")
n.sendMsg("/cubes/rotation/align")

n.sendMsg("/cubes/formation","GRID")
n.sendMsg("/cubes/formation","LINE")
n.sendMsg("/cubes/formation","CIRCLE")
n.sendMsg("/cubes/formation","SQUARE")
n.sendMsg("/cubes/formation","CENTER")

n.sendMsg("/cubes/rotation/axis/x", true)
n.sendMsg("/cubes/rotation/axis/x", false)
n.sendMsg("/cubes/rotation/axis/y", true)
n.sendMsg("/cubes/rotation/axis/y", false)
n.sendMsg("/cubes/rotation/axis/z", true)
n.sendMsg("/cubes/rotation/axis/z", false)

n.sendMsg("/cubes/fill/color/start", 255,150,150)
n.sendMsg("/cubes/fill/color/start", 125,64,150)

n.sendMsg("/cubes/fill/color/end", 255,150,150)
n.sendMsg("/cubes/fill/color/end", 125,64,150)

n.sendMsg("/cubes/scale/base", 5)
n.sendMsg("/cubes/scale/base", 30)
n.sendMsg("/cubes/scale/base", 100)
n.sendMsg("/cubes/scale/offset", 20)
n.sendMsg("/cubes/scale/offset", 100)

n.sendMsg("/cubes/fill", true)
n.sendMsg("/cubes/fill", false)

n.sendMsg("/cubes/fill/alpha", 1.0)
n.sendMsg("/cubes/fill/alpha", 0.5)
n.sendMsg("/cubes/fill/alpha", 0.1)

n.sendMsg("/cubes/length", 5)
n.sendMsg("/cubes/length", 81)
n.sendMsg("/cubes/length", 49)

n.sendMsg("/cubes/stroke/color", 255,0,0)
n.sendMsg("/cubes/stroke/color", 255,125,0)

n.sendMsg("/cubes/stroke/alpha", 0.3)

n.sendMsg("/cubes/stroke/width", 1)
n.sendMsg("/cubes/stroke/width", 5)

n.sendMsg("/cubes/stroke/visible", true)
n.sendMsg("/cubes/stroke/visible", false)

n.sendMsg("/text/load", "kierkegaard.txt")
n.sendMsg("/text/load", "munro_fact.txt")

n.sendMsg("/text/font", "Shree Devanagari 714", 80)
n.sendMsg("/text/font", "SignPainter", 56)

n.sendMsg("/text/visible", true)
n.sendMsg("/text/visible", false)

n.sendMsg("/text/stroke/visible", true)
n.sendMsg("/text/stroke/visible", false)

n.sendMsg("/text/stroke/color",  255,150,150)
n.sendMsg("/text/stroke/color", 125,64,150)

n.sendMsg("/text/fill/color/start",  255,150,150)
n.sendMsg("/text/fill/color/start",  255,255,255)
n.sendMsg("/text/fill/color/start",  125,125,200)

n.sendMsg("/text/fill/color/end",  255,150,150)

n.sendMsg("/text/fill/alpha", 1.0)
n.sendMsg("/text/fill/alpha", 0.4)

n.sendMsg("/text/motion", "FADE")
n.sendMsg("/text/motion", "FADE_ZOOM")
// n.sendMsg("/text/motion", "SPIN")

n.sendMsg("/text/order", "RANDOM")
n.sendMsg("/text/order", "INORDER")
n.sendMsg("/text/order", "NEAR_RANDOM")
