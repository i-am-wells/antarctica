local Element = require 'ui.elements.Element'
local Container = require 'class'(Element)

function Container:init(argtable)
  Element.init(self, argtable)

  self.gap = argtable.gap or 0
  self.children = {}
  for i, child in ipairs(argtable) do
    self.children[i] = child
  end
end

return Container
