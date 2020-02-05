local Class = require 'class'
local MapGenerator = require 'maptools.MapGenerator'

local HillsideMapGenerator = Class(MapGenerator)

do
  local weights = MapGenerator.make16Weights(4)
  weights[1] = 64
  weights[6] = 1 -- vertical grass | dirt
  weights[7] = 1
  weights[10] = 1
  weights[11] = 1 -- vertical dirt | grass
  weights[16] = 8
  HillsideMapGenerator.weights = weights
end

function HillsideMapGenerator:generate(...)
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

  return self:createTilemap(...)
end

return HillsideMapGenerator
