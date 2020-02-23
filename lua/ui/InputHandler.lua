local Class = require 'class'

local InputHandler = Class()

local defaultNoOp = function()
  return setmetatable({}, {
    __index = function() return function() end end
  })
end

function InputHandler:init(argtable)
  -- Do nothing on unrecognized key presses.
  self.keydown = defaultNoOp()
  self.keyup = defaultNoOp()

  self.onKeyDown = function(key, ...)
    self.keydown[key](...)
  end
  self.onKeyUp = function(key, ...)
    self.keyup[key](...)
  end

  self._actions = argtable.actions

  if argtable.keydown then
    self:setKeyDown(argtable.keydown)
  end

  if argtable.keyup then
    self:setKeyUp(argtable.keyup)
  end
end

local setKeys = function(keyToAction, actionToHandler, keyToHandler)
  for key, action in pairs(keyToAction) do
    local handler = actionToHandler[action]
    if __dbg then
      assert(
        type(handler) == 'function',
        string.format('No handler for action "%s"', action)
      )
    end

    keyToHandler[key] = handler
  end
end

function InputHandler:setKeyDown(keyToAction)
  setKeys(keyToAction, self._actions, self.keydown)
end

function InputHandler:setKeyUp(keyToAction)
  setKeys(keyToAction, self._actions, self.keyup)
end

return InputHandler
