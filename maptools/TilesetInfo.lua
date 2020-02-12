local math = require 'math'
local string = require 'string'

local Class = require 'class'
local materials = require 'maptools.materials'
local Point = require 'Point'
local Set = require 'Set'

local TilesetInfo = Class()

function TilesetInfo.getPointKey(patch, x, y)
  local x, y = x or 0, y or 0
  return string.format("%d,%d", patch.x + x, patch.y + y)
end

local storePatch = function(mapping, patch)
  for y = 0, patch.h - 1 do
    for x = 0, patch.w - 1 do
      local point = Point(patch.x + x, patch.y + y)
      mapping[TilesetInfo.getPointKey(patch, x, y)] = point
    end
  end
end

-- Maps IntermediateMap keys to tiles.

function TilesetInfo:init(info)
  self.info = info
  self.mapping = {}
  if info.baseTiles then
    -- copy points into mapping
    for k, point in pairs(info.baseTiles) do
      self.mapping[k] = point
    end
  end
  -- TODO rethink
  --[[
  if info.patches then
  for k, patches in pairs(info.patches) do
  for _, patch in ipairs(patches) do
  storePatch(self.mapping, patch)
  end
  end
  end
  --]]
  --
  self.walkable = Set(info.walkable)

  self.transitions = info.transitions
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

function TilesetInfo:isWalkable(k)
  return self.walkable:has(k)
end

return TilesetInfo
