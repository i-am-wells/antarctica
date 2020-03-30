local Image = require 'image'
local Context = require 'ui.Context'
local InputHandler = require 'ui.InputHandler'
local HorizontalContainer = require 'ui.elements.HorizontalContainer'
local Util = require 'Util'
local bind = Util.bind
local RgbaColor = require 'RgbaColor'
local MenuThings = require 'game2.MenuThings'
local ListMenu = require 'game2.ListMenu'

local MainMenuContext = require 'class'(require 'ui.Context')

function MainMenuContext:init(argtable)
  if __dbg then
    assert(argtable.engine)
  end
   
  self.font = argtable.font

  self.quit_ = false
  self.saveFileName_ = nil

  local screenW, screenH = argtable.engine:getLogicalSize()

  local makeHighlightableText = MenuThings.makeMakeHighlightableText(
    self.font, --[[wrapWidth=]] screenW)

  Util.using({engine = argtable.engine}, function()
    self.titleImage = Image{
      file='res/title.png'
    }

    Context.init(self, {
      draw = bind(self.draw, self),
      inputHandler = InputHandler{
        actions = {
          left = bind(self.left, self),
          right = bind(self.right, self),
          choose = bind(self.choose, self)
        },
        keys = {
          Left = 'left',
          A = 'left',
          Right = 'right',
          D = 'right',
          Tab = 'right',
          Return = 'choose',
          Space = 'choose',
        },
        allowKeyRepeat = false
      }
    })

    self.menu = ListMenu{
      x = 'centered',
      y = 0.6,
      enclosingW = screenW,
      enclosingH = screenH,
      container = HorizontalContainer{
        debugName = 'mainMenuContainer',
        gap = 100,
        makeHighlightableText('Start', bind(self.start, self)),
        makeHighlightableText('Quit', bind(self.quit, self)),
      },
    }
  end) -- end Util.using
end

function MainMenuContext:shouldQuit()
  return self.quit_
end

function MainMenuContext:saveFileName()
  return self.saveFileName_
end

function MainMenuContext:draw()
  if self.parentContext then
    self.parentContext:draw()
  end

  self.titleImage:drawWhole(0, 0)
  self.menu:draw()
end

function MainMenuContext:left(state)
  if state == 'down' then
    self.menu:prev()
  end
end

function MainMenuContext:right(state)
  if state == 'down' then
    self.menu:next()
  end
end

function MainMenuContext:choose(state)
  if state == 'down' then
    self.menu:choose()
  end
end

-- Action handlers
function MainMenuContext:start()
  self.quit_ = false
  --self.saveFileName_ = filename
  self:returnControlToParent()
end

function MainMenuContext:quit()
  self.quit_ = true
  self:returnControlToParent()
end

return MainMenuContext
