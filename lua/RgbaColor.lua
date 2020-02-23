local RgbaColor = require 'class'()

function RgbaColor:init(r, g, b, a)
  self.r = r
  self.g = g
  self.b = b
  self.a = a
end

return RgbaColor
