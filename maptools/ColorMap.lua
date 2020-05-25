local ColorMap = require 'class'()

local empty = {}
local defaultTable = function(default)
  return setmetatable({}, {__index = default})
end

local intToRGB = function(int)
  return (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff
end

local defaultTable = function(defaultFn)
  return setmetatable({}, {
    __index = function(t, k)
      local newVal = defaultFn()
      t[k] = newVal
      return newVal
    end
  })
end

local getRGB = function(map, r, g, b)
  return map.data[r][g][b]
end
local getColor = function(map, color)
  return getRGB(map, color.r, color.g, color.b)
end

local setRGB = function(map, r, g, b, val)
  map.data[r][g][b] = val
end
local setColor = function(map, color, val)
  setRGB(map, color.r, color.g, color.b, val)
end

function ColorMap:init(data)
  self.data = defaultTable(function()
    return defaultTable(function()
      return {}
    end)
  end)
  
  setmetatable(self, {
    __index = getColor,
    __newindex = setColor
  })

  if data then
    for rgb, val in pairs(data) do
      local r, g, b = intToRGB(rgb)
      setRGB(self, r, g, b, val)
    end
  end
end

return ColorMap
