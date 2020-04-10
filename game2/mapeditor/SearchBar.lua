local Context = require 'ui.Context'
local InputHandler = require 'ui.InputHandler'
local Class = require 'class'
local Util = require 'Util'
local bind = Util.bind

local SearchBar = Class(Context)

function SearchBar:init(arg)
  self.engine = engine or arg.engine
  if __dbg then
    assert(self.engine)
  end

  Context.init(self, {
    engine = self.engine,
    stealInput = false,
    inputHandler = InputHandler{
      textInput = bind(self.onTextInput, self),
      textEditing = bind(self.onTextEditing, self),
      actions = {
        choose = bind(self.choose, self),
        banish = bind(self.banish, self),
      },
      keys = {
        Return = 'choose',
        Escape = 'banish'
      }
    }
  })
end

function SearchBar:choose()
  -- TODO
end

function SearchBar:banish()
  
end

function SearchBar:onTextInput(text)
  -- TODO
  print('input:', text)
end

function SearchBar:onTextEditing(text, start, length)
  -- TODO
  print('edit:', text, start, length)
end


return SearchBar
