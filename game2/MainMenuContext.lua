local Image = require 'image'
local Context = require 'ui.Context'
local InputHandler = require 'ui.InputHandler'
local HorizontalContainer = require 'ui.elements.HorizontalContainer'
local HighlightableText = require 'game2.HighlightableText'
local Util = require 'Util'

local MainMenuContext = require 'class'(require 'ui.Context')

function MainMenuContext:init(argtable)
  if __dbg then
    assert(argtable.engine)
  end
   
  self.font = argtable.font

  self.quit_ = false
  self.saveFileName_ = nil

  self.choice = 0

  Util.using({engine = argtable.engine}, function()
    self.titleImage = Image{
      file='res/title.png'
    }

    Context.init(self, {
      draw = Util.bind(self.draw, self),
      inputHandler = InputHandler{
        actions = {
          left = Util.bind(self.left, self),
          right = Util.bind(self.right, self),
          choose = Util.bind(self.choose, self)
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

    -- Render menu choices
    self.uiRoot = HorizontalContainer{
      x = 'centered',
      y = 2/3,
      gap = 100,
      HighlightableText{
        font = self.font,
        text = 'Start',
        action = Util.bind(self.start, self)
      },
      HighlightableText{
        font = self.font,
        text = 'Quit',
        action = Util.bind(self.quit, self)
      }
    }
  end) -- end Util.using

  self:setChoiceHighlight(true)
end

function MainMenuContext:draw()
  if self.parentContext then
    self.parentContext:draw()
  end

  self.titleImage:drawWhole(0, 0)
  self.uiRoot:draw()
end

function MainMenuContext:getChoice()
  return self.uiRoot.children[self.choice+1]
end

function MainMenuContext:setChoiceHighlight(isHighlight)
  self:getChoice():setHighlight(isHighlight)
end

function MainMenuContext:left(state)
  if state == 'down' then
    self:setChoiceHighlight(false)
    self.choice = (self.choice - 1) % #self.uiRoot.children
    self:setChoiceHighlight(true)
  end
end

function MainMenuContext:right(state)
  if state == 'down' then
    self:setChoiceHighlight(false)
    self.choice = (self.choice + 1) % #self.uiRoot.children
    self:setChoiceHighlight(true)
  end
end

function MainMenuContext:choose(state)
  if state == 'down' then
    self:getChoice():executeAction()
  end
end

function MainMenuContext:start()
  self.quit_ = false
  --self.saveFileName_ = filename
  self:returnControlToParent()
end

function MainMenuContext:quit()
  self.quit_ = true
  self:returnControlToParent()
end

function MainMenuContext:shouldQuit()
  return self.quit_
end

function MainMenuContext:saveFileName()
  return self.saveFileName_
end

return MainMenuContext
