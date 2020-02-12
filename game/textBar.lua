local Class = require 'class'
local Image = require 'image'
local Menu = require 'game.menu'

local TextBar = Class(Menu)

TextBar.bgColor = {r=109, g=194, b=202, a=255}
TextBar.textColor = {r=20, g=12, b=28}
TextBar.nameColor = {r=48, g=52, b=109}
TextBar.borderColor = TextBar.nameColor

TextBar.rows = 4
TextBar.cols = 60

TextBar.margin = 5

TextBar.fontFile = 'res/text-6x12.png'
TextBar.fontW = 6
TextBar.fontH = 12

TextBar.nameFontFile = 'res/text-5x9.png'
TextBar.nameFontW = 5
TextBar.nameFontH = 9


function TextBar:init(opt)
  Menu.init(self, opt)

  self.resourceMan = opt.resourceMan

  self.engine = self.resourceMan:get('engine')
  self.font = self.resourceMan:get(self.fontFile, Image, {
    engine = self.engine,
    file = self.fontFile,
    tilew = self.fontW,
    tileh = self.fontH
  })

  self.nameFont = self.resourceMan:get(self.nameFontFile, Image, {
    engine = self.engine,
    file = self.nameFontFile,
    tilew = self.nameFontW,
    tileh = self.nameFontH
  })

  self.baseW = 2 * self.margin + self.cols * self.fontW
  self.baseH = 2 * self.margin + self.rows * self.fontH + self.nameFontH
  self.baseX = self.engine.vw // 2 - self.baseW // 2
  self.baseY = self.engine.vh - self.baseH - 5

  self.innerW = self.baseW - 2 * self.margin

  -- content
  self.text = opt.text
  self.name = opt.name or ''
  self.charsPerFrame = opt.charsPerFrame or 2
end

function TextBar:open(controller)
  self.counter = 0

  -- TODO remove setmetatable
  self.controlMap = setmetatable({
    K = 'choose',
    J = 'back'
  }, {
    --__index = controller.controlMap
  })

  self.onkeydown = setmetatable({
    choose = function() self:onChoose() end,
    back = function() self:onBack() end
  }, {
    --__index = controller.onkeydown
  })

  --self.onkeyup = controller.onkeyup


  Menu.open(self, controller)
end



function TextBar:onChoose()
  self:close()
end


function TextBar:draw()
  -- background and border
  local bg, bdr = self.bgColor, self.borderColor
  self.engine:setColor(bg.r, bg.g, bg.b, bg.a or 255)
  self.engine:fillRect(self.baseX, self.baseY, self.baseW, self.baseH)
  self.engine:setColor(bdr.r, bdr.g, bdr.b, bdr.a or 255)
  self.engine:drawRect(self.baseX, self.baseY, self.baseW, self.baseH)

  local trimmedText = string.sub(self.text, 1, self.counter * self.charsPerFrame // 1 + 1)

  -- draw name
  local nc, tc = self.nameColor, self.textColor
  self.nameFont:colorMod(nc.r, nc.g, nc.b)
  self.nameFont:drawText(self.name, self.baseX + self.margin, self.baseY + self.margin, self.innerW)

  self.font:colorMod(tc.r, tc.g, tc.b)
  self.font:drawText(trimmedText, self.baseX + self.margin, self.baseY + self.margin + self.nameFontH, self.innerW)

  self.counter = self.counter + 1
end


return TextBar

