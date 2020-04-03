local Util = require 'Util'
local Element = require 'class'()

-- Element
--
-- Basic UI class. Handles positioning and actions.
function Element:init(argtable)
  self.context = argtable.context or context

  if __dbg then
    assert(self.context)
  end

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

function Element:containsPoint(x, y)
  return x >= self.x
    and x < (self.x + self.w)
    and y >= self.y
    and y < (self.y + self.h)
end

function Element:onMouseDown(x, y, button, clicks)
  self:executeAction()
end

function Element:onMouseMotion(x, y, dx, dy)
  if self:containsPoint(x, y) then
    self.context:mouseOver(self)
  end
end

function Element:onMouseEnter()
  if self.context.focusedElement and not self:hasFocus() then
    self.context.focusedElement:loseFocus()
  end
  self:gainFocus()
end

function Element:onMouseLeave()
  -- Some elements should lose focus when the mouse leaves. Implement that
  -- behavior by overriding this method.
end

function Element:gainFocus()
  self.context.focusedElement = self
end

function Element:loseFocus()
  self.context.focusedElement = nil
end

function Element:hasFocus()
  return self.context.focusedElement == self
end

return Element
