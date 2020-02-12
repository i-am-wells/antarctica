local Class = require 'class'
local Image = require 'image'

local Overlay = require 'game.overlay'

local StatusText = Class(Overlay)

StatusText.fontFile = 'res/text-6x12.png'
StatusText.fontW = 6
StatusText.fontH = 12

StatusText.margin = 5

StatusText.color = {r=20, g=12, b=28}

function StatusText:init(opt)
  local engine = opt.resourceMan:get('engine')

  self.font = opt.resourceMan:get(self.fontFile, Image, {
    engine = engine,
    file = self.fontFile,
    tilew = self.fontW,
    tileh = self.fontH
  })

  self.drawX = self.margin
  self.drawY = engine.vh - self.margin - self.fontH
  self.drawW = engine.vw - 2 * self.margin

  self.text = opt.text

  Overlay.init(self, opt)
end


function StatusText:draw(idx)
  local y = self.drawY - (self.fontH + self.margin) * (#self.overlayStack - idx)

  -- draw text
  self.font:colorMod(self.color.r, self.color.g, self.color.b)
  self.font:drawText(self.text, self.drawX, y, self.drawW)
end

return StatusText

