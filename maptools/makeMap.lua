-- TODO do this better
local package = require 'package'
package.path = package.path..';./lua/?.lua'

local BiomesImage = require 'maptools.BiomesImage'
local Point = require 'Point'
local Rect = require 'Rect'
local Set = require 'Set'
local Engine = require 'engine'
local Patch = require 'maptools.Patch'
local ReplacePatch = require 'maptools.ReplacePatch'
local PatchFromTileset = require 'maptools.PatchFromTileset'
local m = require 'maptools.materials'
local TilesetInfo = require 'maptools.TilesetInfo'
local Tilemap = require 'tilemap'

local marchingSquares = require 'maptools.marchingSquares'

local Util = require 'Util'
local printf = Util.printf

local baseImageFile = 'res/antarctica-base.png'
local featuresImageFile = 'res/antarctica-features.png'
local outFile = 'antarctica.out.map'

local keyToColor = {
  [m.forest] = {r=143, g=86, b=59}, -- Rope
  [m.conifer] = {r=75, g=105, b=47}, -- Dell
  [m.brown] = {r=102, g=57, b=49}, -- Oiled cedar
  [m.ocean] = {r=124, g=175, b=206},
  [m.beach] = {r=223, g=204, b=161},
  [m.fern] = {r=24, g=35, b=18},
  [m.bigRock] = {r=105, g=106, b=106},
  [m.smallRock] = {r=132, g=126, b=135},
  [m.underbrush] = {r=82, g=75, b=36},
  [m.cliffside] = {r=105, g=106, b=106}, -- TODO
  [m.darkForestFloor] = {r=69, g=40, b=60},

  [m.black] = {r=0, g=0, b=0}, -- black
  [m.forestRoad] = {r=106, g=190, b=48}, -- Christi
  [m.house] = {r=215, g=123, b=186}, -- Plum
  [m.dark] = {r=34, g=32, b=52}, -- Valhalla
} -- TODO named colors (or "color materials" mapped to colors)

local baseGroundMaterials = Set{
  m.forest,
  m.ocean,
  m.beach
}

local rectPointList = function(x, y, w, h)
  local points = {}
  for yy = y, (y + h - 1) do
    for xx = x, (x + w - 1) do
      points[#points+1] = Point(xx, yy)
    end
  end
  return points
end

local features = {
  house = Rect(7, 3, 7, 7),
  smallPlant = Rect(0, 1, 1, 1), -- small plant
  fern = {
    Rect(1, 0, 4, 2), -- fern 1
    Rect(5, 0, 3, 2), -- fern 2
  },
  bigRock = Rect(8, 0, 2, 2),
  smallRock = Rect(10, 0, 1, 1),
  conifer = Rect(15, 0, 7, 10),
}

local antarcticaTilesetInfo = TilesetInfo{
  file = "forest-16x16.png",
  tileWidth = 16,
  tileHeight = 16,

  -- TODO update TilesetInfo

  baseTiles = {
    [m.black] = Point(31, 0),
    [m.forest] = rectPointList(4, 2, 2, 4),
    [m.beach] = rectPointList(0, 22, 4, 2),
    [m.ocean] = Point(24, 0),
    [m.forestRoad] = Point(10, 4),
    [m.house] = Point(31, 0),
    [m.dark] = Point(31, 0),
    [m.darkForestFloor] = Point(3, 5),
    [m.cliffside] = Point(3, 17),
  },
  baseTilesFlags = {
    -- TODO flags here
  },

  transitions = {
    [m.forest] = {
      [m.darkForestFloor] = Point(0, 2),
      [m.cliffside] = Point(0, 14),
      [m.beach] = Point(0, 18)
    }
  },

  features = features
}

local setRect = function(tilemap, layer, x, y, r)
  for yy = 0, r.h - 1 do
    for xx = 0, r.w - 1 do
      tilemap:setTile(layer, x + xx, y + yy, r.x + xx, r.y + yy)
    end
  end
end

local setBump = function(tilemap, layer, x, y)
  tilemap:setFlags(layer, x, y, Tilemap.flags.bumpAll)
end

local setRectBump = function(tilemap, layer, x, y, r)
  for yy = 0, r.h - 1 do
    for xx = 0, r.w - 1 do
      setBump(tilemap, layer, x + xx, y + yy)
    end
  end
end

local keyToFeature = {
  [m.smallRock] = function(t, x, y)
    setRect(t, 1, x, y, features.smallRock)
    setBump(t, 1, x, y)
  end,
  [m.fern] = function(t, x, y)
    local fern = features.fern[1]
    if math.random() < 0.5 then
      fern = features.fern[2]
    end
    setRect(t, 1, x, y, fern)
  end,
  [m.bigRock] = function(t, x, y)
    setRect(t, 1, x, y, features.bigRock)
    setRectBump(t, 1, x, y, features.bigRock)
  end,
  [m.conifer] = function(t, x, y)
    -- TODO fix
    setRect(t, 1, x, y, features.conifer)
  end
}

--[[
--  Make map
--]]
do
  printf('Reading %s...', baseImageFile)
  local img, err = BiomesImage(Engine(), baseImageFile)
  if not img then error(err) end

  printf('Creating base intermediate map...')
  local map = img:createIntermediateMap(keyToColor, --[[emptyKey=]]m.ocean)

  -- Try to recover some memory
  img = nil
  collectgarbage()

  -- Write map file
  printf('Creating base tilemap...')
  local tilemap = map:toBaseTilemap(antarcticaTilesetInfo, 3) 
  tilemap:setSparseLayer(1, true)
  tilemap:setSparseLayer(2, true)

  printf('Marching squares...')
  marchingSquares(map, antarcticaTilesetInfo, tilemap)

  printf('Reading %s...', featuresImageFile)
  local featuresImg, err = BiomesImage(Engine(), featuresImageFile)
  if not featuresImg then error(err) end

  printf('Adding features...')
  featuresImg:applyFeaturesToTilemap(keyToColor, keyToFeature, tilemap)

  printf('Writing to %s...', outFile)
  tilemap:write(outFile)
end
