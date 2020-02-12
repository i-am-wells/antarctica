local Class = require 'class'

local Overlay = Class()

function Overlay:init(opt)
  self.overlayStack = opt.overlayStack

  self.expiry = opt.expiry
  self.overlayCounter = 0

  -- add self to stack
  if opt.index then
    table.insert(self.overlayStack, opt.index, self)
  else
    table.insert(self.overlayStack, self)
  end
end

function Overlay:remove()
  -- find index, remove
  for i, v in ipairs(self.overlayStack) do
    if v == self then
      table.remove(self.overlayStack, i)
      return
    end
  end
end

function Overlay:update()
  self.overlayCounter = self.overlayCounter + 1

  if self.overlayCounter == self.expiry then
    self:remove()
  end
end

return Overlay

