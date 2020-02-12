local ant = require 'antarctica'

local Tilemap = require 'tilemap'
local Engine = require 'engine'
local Object = require 'object'
local ResourceMan = require 'resourceManager'

local objectEditor = function(engine, map, tileset, state, outfile)
  local layer = 1

  local resourceMan = ResourceMan()

  local cameraObj = Object{
    x=0, y=0, layer=layer, image=tileset, tx=16, ty=0, tw=16, th=16
  }
  map:addObject(cameraObj)
  map:setCameraObject(cameraObj)

  map:populate(state, resourceMan)

  engine:run{
    redraw = function(tick, frametime, counter)
      engine:clear()

      map:drawLayerAtCameraObject(tileset, 0, engine.vw, engine.vh, counter)
      map:drawObjectsAtCameraObject(tileset, 1, engine.vw, engine.vh, counter)
    end,

    keydown = function(key, isRepeat)
    end,

    keyup = function(key)

    end,

    mousebuttonup = function(x, y, button)

    end,
  }
end


-- Create engine

do
  local mapfile = arg[2]
  local tilefile = arg[3]
  local statefile = arg[4]
  local outfile = arg[5]

  if not outfile then error('Must provide output file.') end

  -- try to load map and tileset
  local map, err = Tilemap{file=mapfile}
  if not map then error(err) end

  -- calculate view size
  local vw, vh, logicalScale
  do
    local dispX, dispY, dispW, dispH = ant.engine.getDisplayBounds()

    -- aim to fit at most 30 tiles horizontally
    local targetScale = dispW / 16 / 30 // 1 + 1
    --local targetScale = dispH / 16 / 16 // 1
    vw = dispW // targetScale
    vh = dispH // targetScale
    logicalScale = 1
  end

  -- create engine
  local engine, err = Engine{
    title = 'object editor',
    windowflags = ant.engine.fullscreendesktop,
    rendererflags = ant.engine.rendervsync | ant.engine.renderaccelerated | ant.engine.rendertargettexture,
    targetfps = 30
  }
  if not engine then error(err) end

  engine:setLogicalSize(vw, vh)
  engine.vw = vw
  engine.vh = vh
  engine:setColor(255, 255, 255, 255) -- white background

  -- Load tileset
  local tileset = Image{engine=engine, tw=16, th=16, file=tilefile}
  if not tileset then error('failed to load '..tilefile) end

  local state = require(statefile)

  objectEditor(engine, map, tileset, state, outfile)
end
