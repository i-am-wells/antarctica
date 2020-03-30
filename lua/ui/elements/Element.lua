local Element = require 'class'()

function Element:init(argtable)
  self.action = argtable.action
  self.debugName = argtable.debugName

  self.x = 0
  self.y = 0
  self.w = 0
  self.h = 0
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

function Element:setPosition(t)
  self.x = calc(t.x, t.enclosingW, self.w)
  self.y = calc(t.y, t.enclosingH, self.h)
end

function Element:setPositionPixels(x, y)
  self.x = x
  self.y = y
end

function Element:drawAtOwnPosition()
  self:draw(self.x, self.y)
end

function Element:executeAction()
  if self.action then
    self.action()
  end
end

return Element
