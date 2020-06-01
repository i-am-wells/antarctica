local Class = require 'class'

local InputHandler = require 'class'()

local defaultNoOp = function()
  return setmetatable({}, {
    __index = function() return function() end end
  })
end

function InputHandler:init(argtable)
  -- Do nothing on unrecognized key presses.
  self.keys = defaultNoOp()
  self.allowKeyRepeat = argtable.allowKeyRepeat or false

  self.onKeyDown = function(key, mod, repeatCount)
    if repeatCount > 0 and not self.allowKeyRepeat then
      return
    end
    self.keys[key]('down', key, mod, repeatCount)
  end
  self.onKeyUp = function(key, mod, repeatCount)
    self.keys[key]('up', key, mod, repeatCount)
  end

  self._actions = argtable.actions
  self.quit = argtable.quit or function() end
  self.mouseDown = argtable.mouseDown
  self.mouseUp = argtable.mouseUp
  self.mouseMotion = argtable.mouseMotion
  self.mouseWheel = argtable.mouseWheel

  self.textInput = argtable.textInput
  self.textEditing = argtable.textEditing

  if argtable.keys then
    self:setKeys(argtable.keys)
  end
end

function InputHandler:setKeys(keyToAction)
  for key, action in pairs(keyToAction) do
    local handler = self._actions[action]
    if __dbg then
      assert(
        type(handler) == 'function',
        string.format('No handler for action "%s"', action)
      )
    end
    self.keys[key] = handler
  end
end

return InputHandler
