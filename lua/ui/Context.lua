local InputHandler = require 'ui.InputHandler'
local Context = require 'class'()

function Context:init(argtable)
  self.draw = argtable.draw
  self.inputHandler = argtable.inputHandler
  self.engine = engine or argtable.engine
  self.stealInput = true
  if argtable.stealInput ~= nil then
    self.stealInput = false
  end

  if __dbg then
    assert(type(self.draw) == 'function')
    assert(self.inputHandler and self.inputHandler.isA[InputHandler])
  end
end

function Context:registerHandlers(engine)
  self.engine = engine
  -- TODO only set the ones we have?
  --
  if self.stealInput then
    self.engine:on{
      redraw = self.draw,
      keydown = self.inputHandler.onKeyDown,
      keyup = self.inputHandler.onKeyUp
    }
  else
    self.engine:on{
      redraw = self.draw,
      keydown = self.parentContext.inputHandler.onKeyDown,
      keyup = self.parentContext.inputHandler.onKeyUp
    }
  end
end

function Context:takeControlFrom(parentContext, engine)
  if parentContext then
    self.parentContext = parentContext
    self.engine = parentContext.engine
  end
  if engine then
    self.engine = engine
  end
  self:registerHandlers(self.engine)
  self.engine:run()
end

function Context:returnControlToParent()
  self.engine:stop()
  if self.parentContext then
    self.parentContext:registerHandlers(self.engine)
    self.parentContext = nil
    self.engine = nil
  end
end

-- TODO see if this can be removed
Context.default = Context{
  draw = function() end,
  inputHandler = InputHandler{}
}

return Context
