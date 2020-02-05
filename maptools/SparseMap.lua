local Class = require 'class'

local IntermediateMap = require 'maptools.IntermediateMap'

local SparseMap = Class(IntermediateMap)


function SparseMap:init(args)
  args.slim = true
  IntermediateMap.init(self, args)
   
  self.emptyKey = 0

  local gridRowMt = {
    __index = function(row, k)
      if k > 0 and k <= self.w then
        return self.emptyKey
      end
      -- if out of bounds, return nil
    end,

    __newindex = function(row, k, v)
      if k <= 0 or k > self.w or v == self.emptyKey then return end

      local left = row[k-1]
      if left == self.emptyKey then
    end
  }

  for _, row in ipairs(self.grid) do
    setmetatable(row, gridRowMt)
  end
end

function SparseMap:set(x, y, val)

end

return SparseMap

