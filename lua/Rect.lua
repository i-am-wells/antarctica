local Class = require 'class'

local Rect = Class()

function Rect:init(x, y, w, h)
  self.x, self.y, self.w, self.h = x, y, w, h
end

return Rect
