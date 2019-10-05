local BiomesImage = require 'maptools.BiomesImage'

local Class = require 'class'

local NewMapGenerator = Class()

function NewMapGenerator:init(engine)
  self.engine = engine
end

function NewMapGenerator:generate(mapgenInfo)
  if mapgenInfo.strategy ~= 'biomesImage' then
    error(string.format('unknown map generation strategy "%s"',
      mapgenInfo.strategy))
  end
  
  local biomesImage = BiomesImage(self.engine, mapgenInfo.biomesImage)
  local intermediateMap = biomesImage:createIntermediateMap(mapgenInfo.colors)

  for _, startingPoint in ipairs(mapgenInfo.startingPoints) do
    local key = intermediateMap:get(startingPoint.x, startingPoint.y)
    local terrainGenerator = mapgenInfo.generators[key]
    if terrainGenerator then
      terrainGenerator():generate(intermediateMap, startingPoint)
    end
  end

  return intermediateMap
end


return NewMapGenerator
