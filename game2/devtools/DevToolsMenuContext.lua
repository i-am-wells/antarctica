local VerticalContainer = require 'ui.elements.VerticalContainer'
local Text = require 'ui.elements.Text'
local Util = require 'Util'
local bind, using = Util.bind, Util.using
local InputHandler = require 'ui.InputHandler'
local Context = require 'ui.Context'
local MenuThings = require 'game2.MenuThings'
local ListMenu = require 'game2.ListMenu'
local DevToolsMenuContext = require 'class'(Context)

function DevToolsMenuContext:init(argtable)
  if __dbg then
    assert(argtable.font)
  end
  self.font = argtable.font
  
  local wrapWidth = 300 -- arbitrary
  local makeHighlightableText = MenuThings.makeMakeHighlightableText(
    self.font, wrapWidth)
  
  using({engine=self.engine, context=self}, function()
    self.menuOptions = VerticalContainer{
      gap = 8,
      makeHighlightableText('Map editor', bind(self.mapEdit, self)),
      makeHighlightableText('Cancel', bind(self.returnControlToParent, self))
    }

    self.root = VerticalContainer{
      debugName = "DevToolsMenuVerticalContainer",
      gap = 16,
      Text{
        font = argtable.font,
        text = "Dev Tools",
        width = wrapWidth
      },
      self.menuOptions
    }
    self.root:setPositionPixels(16, 16)
  end)

  -- ListMenu only handles selection logic here. Drawing is done by root.
  self.menu = ListMenu{container = self.menuOptions}
 
  Context.init(self, {
    engine = argtable.engine,
    stealInput = argtable.stealInput,
    draw = bind(self.draw, self),
    inputHandler = InputHandler{
      actions = {
        up = bind(self.up, self),
        down = bind(self.down, self),
        choose = bind(self.choose, self),
        quit = bind(self.quit, self),
      },
      keys = {
        Up = 'up',
        Down = 'down',
        Space = 'choose',
        Return = 'choose',
        Escape = 'quit',
      },
      allowKeyRepeat = false,
      mouseDown = self.menu:bindMouseDownHandler(),
      mouseUp = self.menu:bindMouseUpHandler(),
      mouseMotion = self.menu:bindMouseMotionHandler(),
    },
  })

end

function DevToolsMenuContext:mapEdit()
  -- TODO
  print('map editor')
end

function DevToolsMenuContext:up(state)
  if state == 'down' then
    self.menu:prev()
  end
end

function DevToolsMenuContext:down(state)
  if state == 'down' then
    self.menu:next()
  end
end

function DevToolsMenuContext:choose(state)
  if state == 'down' then
    self.menu:choose()
  end
end

function DevToolsMenuContext:quit()
  self:returnControlToParent()
end

function DevToolsMenuContext:draw(...)
  if self.parentContext then
    self.parentContext:draw(...)
  end
  self.root:drawAtOwnPosition()
end

return DevToolsMenuContext
