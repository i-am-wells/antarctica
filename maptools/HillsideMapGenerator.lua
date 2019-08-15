local Class = require 'class'
local MapGenerator = require 'maptools.MapGenerator'

local HillsideMapGenerator = Class(MapGenerator)

do
  local weights = MapGenerator.make16Weights(2)
  weights[1] = 128
  weights[7] = 1
  weights[10] = 1
  weights[16] = 16
  HillsideMapGenerator.weights = weights
end

function HillsideMapGenerator:generate(mapping)
  -- Fill in map top to bottom, back and forth.
  for y = 0, (self.h-1) do
    if (y % 2) == 0 then
      for x = 0, (self.w-1) do
        self:fillInSquare(self.weights, x, y)
      end
    else
      for x = (self.w-1), 0, -1 do
        self:fillInSquare(self.weights, x, y)
      end
    end
  end

  return self:createTilemap(mapping)
end

return HillsideMapGenerator
