local math = require 'math'
local Container = require 'ui.elements.Container'
local dlog = require 'Util'.dlog
local HorizontalContainer = require 'class'(Container)

function HorizontalContainer:init(argtable)
  Container.init(self, argtable)
  -- Calculate own size
  self.w = self.childrenSumW + (#self.children * self.gap) - self.gap
  self.h = self.childMaxH
end

function HorizontalContainer:draw(x, y)
  -- TODO this shouldn't really be here
  self:setPositionPixels(x, y)
  for _, child in ipairs(self.children) do
    child:draw(x, y)
    x = x + child.w + self.gap
  end
end

return HorizontalContainer
