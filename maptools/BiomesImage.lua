local Class = require 'class'
local Image = require 'image'
local IntermediateMap = require 'maptools.IntermediateMap'
local Util = require 'Util'
local printf = Util.printf

local BiomesImage = Class(Image)

local getKeyFromColor = function(keyToColor, color, colorCache)
  local colorAsInt = (color.r << 16) | (color.g << 8) | color.b
  local cachedKey = colorCache[colorAsInt]
  if cachedKey then
    return cachedKey
  end

  -- If the key wasn't cached, find it in keyToColor.
  for key, color2 in pairs(keyToColor) do
    if color.r == color2.r and color.g == color2.g and color.b == color2.b then
      colorCache[colorAsInt] = key
      return key
    end
  end

  -- Didn't find the key.
  return nil
end

function BiomesImage:init(engine, file)
  Image.init(self, {engine=engine, file=file, keepSurface=true})
end

function BiomesImage:createIntermediateMap(keyToColor, emptyKey, optionalMap)
  if optionalMap then assert(optionalMap.isA[IntermediateMap]) end

  local colorCache = {}

  local intermediate = optionalMap or IntermediateMap{
    w = self.w,
    h = self.h, 
    defaultGridValue = emptyKey,
    slim = true
  }

  for y = 1, self.h do
    for x = 1, self.w do
      local rgb = self:getPixel(x-1, y-1)
      intermediate:set(x, y, getKeyFromColor(keyToColor, rgb, colorCache))
    end
  end

  return intermediate
end

function BiomesImage:applyFeaturesToTilemap(keyToColor, keyToFeature, tilemap)
  --[[
  -- Make sure a feature is present for each key in keyToColor
  for key, color in pairs(keyToColor) do
  assert(type(keyToFeature[key]) == 'function')
  end
  --]]

  local colorCache = {}

  for y = 1, self.h do
    for x = 1, self.w do
      local rgb = self:getPixel(x-1, y-1)
      local key = getKeyFromColor(keyToColor, rgb, colorCache)
      if key == nil then
        printf('warning: no key for color r=%d,g=%d,b=%d', rgb.r, rgb.g, rgb.b)
      elseif keyToFeature[key] then
        keyToFeature[key](tilemap, x, y)
      end
    end
  end
end

return BiomesImage
