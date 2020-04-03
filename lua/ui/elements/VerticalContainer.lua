local math = require 'math'
local Container = require 'ui.elements.Container'
local dlog = require 'Util'.dlog
local VerticalContainer = require 'class'(Container)

function VerticalContainer:init(argtable)
  Container.init(self, argtable)

  -- Calculate own size
  self.w = self.childMaxW
  self.h = self.childrenSumH + (#self.children * self.gap) - self.gap
end

function VerticalContainer:draw(x, y)
  -- TODO this shouldn't really be here
  self:setPositionPixels(x, y)
  
  for _, child in ipairs(self.children) do
    child:draw(x, y)
    y = y + child.h + self.gap
  end
end

return VerticalContainer
