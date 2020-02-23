local Element = require 'ui.elements.Element'
local Text = require 'class'(Element)

function Text:init(argtable)
  Element.init(self, argtable)

  self.font = argtable.font or font or error('font required')
  self.text = argtable.text

  local ew, eh = self.font.engine:getLogicalSize()
  self.wrapWidth = ew

  self.w, self.h = self.font:textSize(self.text, self.wrapWidth)
end

function Text:setColor(rgba)
  self.font:colorMod(rgba.r, rgba.g, rgba.b)
  self.font:alphaMod(rgba.a)
end

function Text:draw(x, y)
  self.font:drawText(self.text, x, y, self.wrapWidth)
end

return Text
