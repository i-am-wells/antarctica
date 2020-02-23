local Element = require 'class'()

function Element:init(argtable)
  self.engine = engine or argtable.engine
  self.rawX = argtable.x
  self.rawY = argtable.y
  self.action = argtable.action
  -- TODO maybe inherit from Rectangle
  self.x = 0
  self.y = 0
  self.w = 0
  self.h = 0
  self:recalculatePosition()
end

local calc = function(rawP, d, thingSize)
  if rawP == nil then
    return 0
  end

  if type(rawP) == 'string' then
    if rawP == 'centered' then
      return (d // 2) - (thingSize // 2)
    end
  elseif rawP < 1 then
    return rawP * d // 1
  else
    return rawP
  end
end

function Element:recalculatePosition()
  local w, h = self.engine:getLogicalSize()
  self.x, self.y = calc(self.rawX, w, self.w), calc(self.rawY, h, self.h)
end

function Element:executeAction()
  if self.action then
    self.action()
  end
end

return Element
