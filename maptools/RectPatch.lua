local Class = require 'class'
local Patch = require 'maptools.Patch'
local TilesetInfo = require 'maptools.TilesetInfo'

local RectPatch = Class(Patch)

function RectPatch:init(args)
  Patch.init(self, args)
  self.rect = args.rect
end

function RectPatch:patch(intermediateMap, ix, iy)
  for y = 0, self.rect.h - 1 do
    for x = 0, self.rect.w - 1 do
      intermediateMap:set(ix + x, iy + y, TilesetInfo.getPointKey{x=x, y=y})
    end
  end
end

function RectPatch:tryReplace(intermediateMap, ix, iy)
  self:match(intermediateMap, ix, iy, function()
    self:patch(intermediateMap, ix, iy)
  end)
end

return RectPatch
