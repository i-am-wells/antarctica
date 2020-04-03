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
  if self.stealInput then
    self.engine:on{
      redraw = self.draw,
      keydown = self.inputHandler.onKeyDown,
      keyup = self.inputHandler.onKeyUp,
      mousebuttondown = self.inputHandler.mouseDown,
      mousebuttonup = self.inputHandler.mouseUp,
      mousemotion = self.inputHandler.mouseMotion,
    }
  else
    self.engine:on{
      redraw = self.draw,
      keydown = self.parentContext.inputHandler.onKeyDown,
      keyup = self.parentContext.inputHandler.onKeyUp,
      mousebuttondown = self.parentContext.inputHandler.mouseDown,
      mousebuttonup = self.parentContext.inputHandler.mouseUp,
      mousemotion = self.parentContext.inputHandler.mouseMotion,
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
  self.engine:removeHandlers()

  if self.parentContext then
    self.parentContext:registerHandlers(self.engine)
    self.parentContext = nil
  end
  self.engine = nil
end

function Context:mouseOver(element, x, y, dx, dy)
  if element ~= self.mouseOverElement then
    if self.mouseOverElement then
      self.mouseOverElement:onMouseLeave()
    end
    self.mouseOverElement = element
    if element then
      element:onMouseEnter()
    end
  end
end

return Context
