local Class = require 'class' 
local Point = require 'Point'
local IntermediateMap = require 'maptools.IntermediateMap'
local materials = require 'maptools.materials'

local Patch = Class(IntermediateMap)

function Patch:init(args)
  if type(args.data) == 'table' then
    -- Learn dimensions from patch data
    local rows = #(assert(args.data))
    local cols = #(assert(args.data[1]))

    IntermediateMap.init(self, {w=cols, h=rows})

    -- Copy patch data
    for y = 1, rows do
      for x = 1, cols do
        local pdata = args.data[y][x]
        local key = materials.any
        if pdata > 0 then
          key = args.keys[pdata]
        end
        assert(key ~= nil)
        self.grid[y][x] = key
      end
    end
  else
    IntermediateMap.init(self, {w=args.w, h=args.h})
  end
  self.origin = args.origin or Point(1, 1)
end

-- If the patch matches the map at point (ix, iy), call matchCallback(). 
function Patch:match(intermediateMap, ix, iy, matchCallback)
  for y = 1, self.h do
    local yy = iy + y - self.origin.y
    for x = 1, self.w do
      local xx = ix + x - self.origin.x
      local patchVal = self.grid[y][x]

      if patchVal ~= materials.any then
        if patchVal ~= intermediateMap:get(xx, yy) then
          return -- No match
        end
      end
    end
  end

  -- Everything matched
  matchCallback()
end

function Patch:apply(intermediateMap, ix, iy)
  for y = 1, self.h do
    local yy = y + iy - self.origin.y
    local ownRow = self.grid[y]
    for x = 1, self.w do
      local xx = x + ix - self.origin.x
      local k = ownRow[x]
      if k ~= materials.any then
        intermediateMap:set(xx, yy, k)
      end
    end
  end
end

return Patch
