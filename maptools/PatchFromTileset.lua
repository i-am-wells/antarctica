local Class = require 'class'
local Point = require 'Point'

local Patch = require 'maptools.Patch'
local TilesetInfo = require 'maptools.TilesetInfo'

local PatchFromTileset = Class(Patch)

-- TODO consider adding 'materials.any' mask

function PatchFromTileset:init(x, y, w, h)
  Patch.init(self, {w=w, h=h})

  for yy = 1, h do
    for xx = 1, w do
      self:set(xx, yy, TilesetInfo.getPointKey(Point(x + xx - 1, y + yy - 1)))
    end
  end
end

return PatchFromTileset
