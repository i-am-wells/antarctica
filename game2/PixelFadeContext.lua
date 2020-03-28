local Util = require 'Util'
local Context = require 'ui.Context'
local InputHandler = require 'ui.InputHandler'
local RgbaColor = require 'RgbaColor'
local Image = require 'image' 
local PixelFadeContext = require 'class'(Context)

PixelFadeContext.fadeIn = 0
PixelFadeContext.fadeOut = 1

function PixelFadeContext:init(argtable)
  Context.init(self, {
    engine = argtable.engine,
    stealInput = argtable.stealInput,
    inputHandler = InputHandler{},
    draw = Util.bind(self.draw, self)
  })

  self.drawColor = argtable.drawColor or RgbaColor(0, 0, 0, 255)
  self.drawCounter = 0
  self.frameCounter = 0
  self.nFrames = 8
  self.frameDuration = argtable.frameDuration or 8

  self.w, self.h = self.engine:getLogicalSize()

  -- TODO use an intermediate image to avoid expensive drawing in frames 6 and 7
  --self.image = Image{engine=engine, w=self.w, h=self.h}

  local direction = argtable.direction
  if __dbg then
    assert(direction == 'in' or direction == 'out')
  end
  
  if direction == 'out' then
    self.first = 1
    self.di = 1
  elseif direction == 'in' then
    self.first = self.nFrames
    self.di = -1
  end
end

local drawPixels = function(engine, w, h, modX, modY, offX, offY)
  for y = offY, h, modY do
    for x = offX, w, modX do
      engine:drawPixel(x, y)
    end
  end
end

local drawFunctions = {
  -- 1
  function(engine, w, h)
    drawPixels(engine, w, h, 4, 4, 0, 0)
  end,

  -- 2
  function(engine, w, h)
    drawPixels(engine, w, h, 4, 4, 0, 0)
    drawPixels(engine, w, h, 4, 4, 2, 2)
  end,

  -- 3
  function(engine, w, h)
    drawPixels(engine, w, h, 2, 2, 0, 0)
  end,

  -- 4
  function(engine, w, h)
    drawPixels(engine, w, h, 2, 2, 0, 0)
    drawPixels(engine, w, h, 2, 2, 1, 1)
  end,

  -- 5
  function(engine, w, h)
    drawPixels(engine, w, h, 2, 2, 0, 0)
    drawPixels(engine, w, h, 1, 2, 0, 1)
  end,
 
  -- 6
  function(engine, w, h)
    drawPixels(engine, w, h, 2, 2, 0, 0)
    drawPixels(engine, w, h, 1, 2, 0, 1)
    drawPixels(engine, w, h, 4, 4, 1, 0)
    drawPixels(engine, w, h, 4, 4, 3, 2)
  end,
  
  -- 7
  function(engine, w, h)
    drawPixels(engine, w, h, 2, 2, 0, 0)
    drawPixels(engine, w, h, 1, 2, 0, 1)
    drawPixels(engine, w, h, 4, 4, 1, 0)
    drawPixels(engine, w, h, 4, 4, 3, 2)
    drawPixels(engine, w, h, 4, 4, 1, 2)
  end,

  -- 8
  function(engine, w, h)
    drawPixels(engine, w, h, 1, 1, 0, 0)
  end
}

function PixelFadeContext:draw(...)
  if self.parentContext then
    self.parentContext:draw(...)
  end

  local last = self.first + (self.frameCounter + self.di)

  for i = self.first, last, self.di do
    drawFunctions[i](self.engine, self.w, self.h)
  end

  self.drawCounter = self.drawCounter + 1
  if self.drawCounter == self.frameDuration then
    self.frameCounter = self.frameCounter + 1
    self.drawCounter = 0
  end
  
  if self.frameCounter == self.nFrames then
    self:returnControlToParent()
  end
end

return PixelFadeContext
