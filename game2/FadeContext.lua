local Util = require 'Util'
local Context = require 'ui.Context'
local InputHandler = require 'ui.InputHandler'
local FadeContext = require 'class'(Context)

-- TODO change to pixel fade 

function FadeContext:init(argtable)
  Context.init(self, {
    engine = argtable.engine,
    stealInput = argtable.stealInput,
    inputHandler = InputHandler{},
    draw = Util.bind(self.draw, self)
  })

  if __dbg then
    assert(argtable.to or argtable.from)
  end

  self.frames = argtable.frames
  if argtable.to then
    self.color = argtable.to
    self.currentFrame = 0
    self.dframe = 1
    self.target = self.frames
  elseif argtable.from then
    self.color = argtable.from
    self.currentFrame = self.frames - 1
    self.dframe = -1
    self.target = -1
  end
end

function FadeContext:draw(...)
  if self.parentContext then
    self.parentContext:draw(...)
  end

  local rgb = self.color
  local alpha = 255 * self.currentFrame / self.frames // 1
  self.engine:setColor(rgb.r, rgb.g, rgb.b, alpha)
  self.engine:fillRect(0, 0, self.engine.vw, self.engine.vh)

  self.currentFrame = self.currentFrame + self.dframe
  if self.currentFrame == self.target then
    self:returnControlToParent()
  end
end

return FadeContext
