local printf = require 'Util'.printf
local bind = require 'Util'.bind
local ListMenu = require 'class'()

function ListMenu:init(argtable)
  if __dbg then
    assert(argtable.container)
  end

  self.container = argtable.container
  self.container:setPosition{
    x = argtable.x or 0,
    y = argtable.y or 0,
    enclosingW = argtable.enclosingW or 0,
    enclosingH = argtable.enclosingH or 0
  }

  self:setChoice(0)
end

function ListMenu:getChoice()
  return self.container.children[self.choice+1]
end

function ListMenu:setChoice(idx)
  if __dbg then
    assert(idx >= 0)
    if #self.container.children > 0 then
      assert(idx < #self.container.children)
    end
  end
  self.choice = idx
  if self:getChoice() then
    self:getChoice():gainFocus()
  end
end

function ListMenu:prev()
  self:getChoice():loseFocus()
  self.choice = (self.choice - 1) % #self.container.children
  self:getChoice():gainFocus()
end

function ListMenu:next()
  self:getChoice():loseFocus()
  self.choice = (self.choice + 1) % #self.container.children
  self:getChoice():gainFocus()
end

function ListMenu:choose()
  self:getChoice():executeAction()
end

function ListMenu:draw()
  self.container:drawAtOwnPosition()
end

function ListMenu:onMouseDown(x, y, button, clicks)
  if self.container:containsPoint(x, y) then
    self.container:onMouseDown(x, y, button, clicks)
  end
end

function ListMenu:bindMouseDownHandler()
  return bind(self.onMouseDown, self)
end

function ListMenu:onMouseUp(x, y, button)
  -- TODO ????
end

function ListMenu:bindMouseUpHandler()
  return bind(self.onMouseUp, self)
end

function ListMenu:onMouseMotion(x, y, dx, dy)
  if self.container:containsPoint(x, y) then
    self.container:onMouseMotion(x, y, dx, dy)
  else
    self.container.context:mouseOver(nil)
  end

  -- update choice
  local focusedElement = self.container.context.focusedElement
  if focusedElement ~= nil then
    self.choice = self.container:getChildIndex(focusedElement)
    assert(self.choice ~= nil) -- , focusedElement.debugName..' is not a child of '..self.container.debugName)
  end
end

function ListMenu:bindMouseMotionHandler()
  return bind(self.onMouseMotion, self)
end

return ListMenu
