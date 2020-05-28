local HighlightableText = require 'game2.HighlightableText'
local RgbaColor = require 'RgbaColor'

local textColor = RgbaColor(0, 0, 0)
local shadowColor = RgbaColor(0x80, 0x80, 0x80)
local highlightColor = RgbaColor(0xc0, 0xc0, 0xc0)

local textShadow = {x=1, y=1, color=shadowColor}

return {
  makeMakeHighlightableText = function(font, wrapWidth, context)
    return function(text, action)
      return HighlightableText{
        debugName = 'HighlightableText_'..text,
        font = font,
        width = wrapWidth,
        shadow = textShadow,
        text = text,
        action = action,
        color = textColor,
        highlight = highlightColor,
        context = context
      }
    end
  end
}
