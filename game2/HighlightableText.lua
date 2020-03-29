local RgbaColor = require 'RgbaColor'
local Text = require 'ui.elements.Text'
local HighlightableText = require 'class'(Text)

local blinkDuration = 15
local blinkCycle = 30

function HighlightableText:init(argtable)
  Text.init(self, argtable)

  self.highlight = false
  self.normalColor = argtable.color or RgbaColor(0, 0, 0)
  self.highlightColor = argtable.highlight or RgbaColor(255, 255, 255)
  self.counter = 0
end

function HighlightableText:setHighlight(highlight)
  self.highlight = highlight
  self.highlightNow = false
  self.counter = 0
end

function HighlightableText:draw(x, y)
  if self.highlight then
    -- Blink.
    if self.counter == 0 then
      self.highlightNow = true
    elseif self.counter == blinkDuration then
      self.highlightNow = false
    end
    self.counter = (self.counter + 1) % blinkCycle
  end

  -- TODO set shadow color
  if self.highlightNow then
    self.color = self.highlightColor
  else
    self.color = self.normalColor
  end

  Text.draw(self, x, y)
end

return HighlightableText
