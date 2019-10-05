local Class = require 'class'
local materials = require 'maptools.materials'

local TilesetInfo = Class()

-- Maps IntermediateMap keys to tiles.

function TilesetInfo:init(info)
  self.info = info
  self.mapping = {}
  if info.tiles then
    for name, point in pairs(info.tiles) do
      self.mapping[materials[name]] = point
    end
  end
end

function TilesetInfo:getTile(key)
  return self.mapping[key]
end

return TilesetInfo
