local math = require 'math'
local string = require 'string'

local Class = require 'class'
local materials = require 'maptools.materials'
local Point = require 'Point'


local TilesetInfo = Class()

-- TODO this is used for points; shouldn't be named for patches
function TilesetInfo.getPatchKey(patch, x, y)
  return string.format("%d,%d", patch.x + x, patch.y + y)
end

local storePatch = function(mapping, patch)
  for y = 0, patch.h - 1 do
    for x = 0, patch.w - 1 do
      local point = Point(patch.x + x, patch.y + y)
      mapping[TilesetInfo.getPatchKey(patch, x, y)] = point
    end
  end
end

-- Maps IntermediateMap keys to tiles.

function TilesetInfo:init(info)
  self.info = info
  self.mapping = {}
  if info.tiles then
    for name, point in pairs(info.tiles) do
      local material = materials[name]
      if not material then error("couldn't find material for "..name) end
      self.mapping[material] = point
    end
  end
  if info.patches then
    for k, patches in pairs(info.patches) do
      for _, patch in ipairs(patches) do
        storePatch(self.mapping, patch)
      end
    end
  end

  self.walkable = {}
  if info.walkable then
    for k, v in pairs(info.walkable) do
      if v then
        local points = self.mapping[materials[k]]
        if points.isA and points.isA[Point] then points = {point} end

        for _, point in ipairs(points) do
          self.walkable[TilesetInfo.getPatchKey(point, 0, 0)] = true
        end
      end
    end
  end
end

function TilesetInfo:getTile(key)
  local val = self.mapping[key]
  if not val then
    error(string.format("No value for key %s (%s)", tostring(key), type(key)))
  end
  if val.isA and val.isA[Point] then
    return val
  else
    -- Assume it's a list, choose random point
    return val[math.random(#val)]
  end
end

function TilesetInfo:getWalkable(point)
  return self.walkable[TilesetInfo.getPatchKey(point, 0, 0)]
end

return TilesetInfo
