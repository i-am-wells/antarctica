local math = require 'math'
local Container = require 'ui.elements.Container'
local HorizontalContainer = require 'class'(Container)

function HorizontalContainer:init(argtable)
  Container.init(self, argtable)

  -- Calculate own size
  self.w, self.h = 0, 0
  for _, child in ipairs(self.children) do
    self.w = self.w + child.w + self.gap
    self.h = math.max(self.h, child.h)
  end
  self.w = self.w - self.gap
  self:recalculatePosition()
end

function HorizontalContainer:draw()
  local x, y = self.x, self.y
  for _, child in ipairs(self.children) do
    child:draw(x, y)
    x = x + child.w + self.gap
  end
end

return HorizontalContainer
