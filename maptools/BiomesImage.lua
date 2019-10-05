local Class = require 'class'
local Image = require 'image'

local IntermediateMap = require 'maptools.IntermediateMap'

local BiomesImage = Class(Image)

local getKeyFromColor = function(keyToColor, color, colorCache)
  local colorString = string.format('%d,%d,%d', color.r, color.g, color.b)
  local cachedKey = colorCache[colorString]
  if cachedKey then
    return cachedKey
  end

  -- If the key wasn't cached, find it in keyToColor.
  for key, color2 in pairs(keyToColor) do
    if color.r == color2.r and color.g == color2.g and color.b == color2.b then
      colorCache[colorString] = key
      return key
    end
  end

  -- Didn't find the key.
  return nil
end

function BiomesImage:init(engine, file)
  Image.init(self, {engine=engine, file=file, keepSurface=true})
end

function BiomesImage:createIntermediateMap(keyToColor)
  local colorCache = {}

  local intermediate = IntermediateMap{
    w = self.w,
    h = self.h, 
    defaultGridValue = 1
  }

  local imageData = self:getPixels()
  for y = 1, self.h do
    local row = imageData[y]
    for x = 1, self.w do
      intermediate:set(x, y, getKeyFromColor(keyToColor, row[x], colorCache))
    end
  end

  return intermediate
end

function BiomesImage:getColors()
  
end

function BiomesImage:printColors()
  print('{')
  for i, color in ipairs(self:getColors()) do
    print(string.format('  {r=%d, g=%d, b=%d},', color.r, color.g, color.b))
  end
  print('}')
end

return BiomesImage
