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

return Container
