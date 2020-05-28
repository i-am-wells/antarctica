local math = require 'math'
local Text = require 'ui.elements.Text'

return require 'class'(Text, {
  init = function(self, arg)
    Text.init(self, arg)
    self.engine = arg.engine or engine
    if __dbg then assert(self.engine) end
    -- Cursor position begins at 0 for right before the first character and ends
    -- at #self.text which is the position after the last character.
    self.cursorPosition = arg.cursorPosition or #self.text
    self.wink = false
    self.counter = 0
    self.updateCallback = arg.onUpdate
  end,

  isCursorAtEnd = function(self)
    return self.cursorPosition == #self.text
  end,

  setText = function(self, text)
    self.text = text
    self.cursorPosition = #text
    self:onUpdate()
  end,

  setCursorPosition = function(self, cursorPosition)
    self.cursorPosition = math.max(0, math.min(#self.text, cursorPosition))
  end,

  moveCursor = function(self, delta)
    self:setCursorPosition(self.cursorPosition + delta)
  end,

  insertAtCursor = function(self, str)
    self.text = self.text:sub(0, self.cursorPosition) .. str .. self.text:sub(self.cursorPosition + 1)
    self.cursorPosition = self.cursorPosition + #str
    self:onUpdate()
  end,

  -- Character position starts at 1.
  delete = function(self, position)
    self.text = self.text:sub(1, position - 1) .. self.text:sub(position + 1)
    if position <= self.cursorPosition then
      self:setCursorPosition(self.cursorPosition - 1)
    end
    self:onUpdate()
  end,

  deleteBeforeCursor = function(self)
    self:delete(self.cursorPosition)
  end,

  deleteAfterCursor = function(self)
    self:delete(self.cursorPosition + 1)
  end,

  onUpdate = function(self)
    if self.updateCallback then
      self.updateCallback(self.text)
    end
  end,

  draw = function(self, x, y)
    Text.draw(self, x, y)
    if not self.wink then
      local cursorX = x + self.font.tw * self.cursorPosition
      self.engine:drawLine(cursorX, y, cursorX, y + self.font.th)
    end

    self.counter = self.counter + 1
    if self.counter == 15 then
      self.wink = not self.wink
      self.counter = 0
    end
  end,
})
