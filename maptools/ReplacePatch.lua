local Class = require 'class'
local Patch = require 'maptools.Patch'

local ReplacePatch = Class(Patch)

function ReplacePatch:init(args)
  self.pattern = assert(args.pattern)
  self.out = assert(args.out)
end

function ReplacePatch:tryReplace(intermediateMap, x, y)
  self.pattern:match(intermediateMap, x, y, function()
    self.out:apply(intermediateMap, x - self.pattern.origin.x + 1, y - self.pattern.origin.y + 1)
  end)
end

return ReplacePatch
