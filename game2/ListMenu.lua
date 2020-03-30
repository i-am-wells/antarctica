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
  self.choice = 0
  self:setChoiceHighlight(true)
end

function ListMenu:getChoice()
  return self.container.children[self.choice+1]
end

function ListMenu:setChoiceHighlight(isHighlight)
  if __dbg then
    assert(self:getChoice().setHighlight)
  end
  self:getChoice():setHighlight(isHighlight)
end

function ListMenu:prev()
  self:setChoiceHighlight(false)
  self.choice = (self.choice - 1) % #self.container.children
  self:setChoiceHighlight(true)
end

function ListMenu:next()
  self:setChoiceHighlight(false)
  self.choice = (self.choice + 1) % #self.container.children
  self:setChoiceHighlight(true)
end

function ListMenu:choose()
  self:getChoice():executeAction()
end

function ListMenu:draw()
  self.container:drawAtOwnPosition()
end

return ListMenu
