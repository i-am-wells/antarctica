local RgbaColor = require 'RgbaColor'
local Element = require 'ui.elements.Element'
local Text = require 'class'(Element)

-- Default colors
Text.color = RgbaColor(0, 0, 0)
Text.shadowColor = RgbaColor(128, 128, 128)

function Text:init(argtable)
  Element.init(self, argtable)

  if __dbg then
    assert(argtable.width)
  end
  self.wrapWidth = argtable.width

  self.font = argtable.font or font or error('font required')
  self.text = argtable.text

  if type(argtable.shadow) == 'table' then
    self.hasShadow = true
    self.shadowX = argtable.shadow.x or 1
    self.shadowY = argtable.shadow.y or 1
    if type(argtable.shadow.color) == 'table' then
      self.shadowColor = argtable.shadow.color
    end
  end

  self.w, self.h = self.font:textSize(self.text, self.wrapWidth)

end

function Text:setColor(rgba)
  self.font:colorMod(rgba.r, rgba.g, rgba.b)
  self.font:alphaMod(rgba.a)
end

function Text:setColorAndDraw(color, x, y)
  self:setColor(color)
  self.font:drawText(self.text, x, y, self.wrapWidth)
end

function Text:draw(x, y)
  if self.hasShadow then
    self:setColorAndDraw(self.shadowColor, x + self.shadowX, y + self.shadowY)
  end
  self:setColorAndDraw(self.color, x, y)
end

return Text
