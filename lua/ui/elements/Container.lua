local math = require 'math'
local Element = require 'ui.elements.Element'
local Container = require 'class'(Element)

function Container:init(argtable)
  Element.init(self, argtable)

  self.gap = argtable.gap or 0
  self.children = {}
  self.childrenSumW, self.childrenSumH = 0, 0
  self.childMaxW, self.childMaxH = 0, 0
  for i, child in ipairs(argtable) do
    self.children[i] = child
    self.childrenSumW = self.childrenSumW + child.w
    self.childrenSumH = self.childrenSumH + child.h
    self.childMaxW = math.max(self.childMaxW, child.w)
    self.childMaxH = math.max(self.childMaxH, child.h)
  end
end

-- TODO this could be a binary search
function Container:findChild(x, y)
  for _, child in ipairs(self.children) do
    if child:containsPoint(x, y) then
      return child
    end
  end
  return nil
end

function Container:onMouseDown(x, y, button, clicks)
  local child = self:findChild(x, y)
  if child then
    child:onMouseDown(x, y, button, clicks)
  end
end

function Container:onMouseUp(x, y, button)
  -- TODO ????
end

function Container:onMouseMotion(x, y, dx, dy)
  local child = self:findChild(x, y)
  if not child then
    self.context:mouseOver(nil)
  else
    child:onMouseMotion(x, y, dx, dy)
  end
end

function Container:getChildIndex(element)
  for i, child in ipairs(self.children) do
    if child == element then
      return i - 1
    end
  end
  return nil
end

function Container:clearChildren()
  self.children = {}
end

function Container:addChild(child)
  self.children[#self.children+1] = child
end

function Container:sort(comp)
  table.sort(self.children, comp)
end

return Container
