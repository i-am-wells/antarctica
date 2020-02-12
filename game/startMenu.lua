
local Class = require 'class'
local Image = require 'image'

local StartMenu = Class()

function StartMenu:init(engine, resourceMan)
  self.engine = engine
  self.resourceMan = resourceMan

  -- need: title image, font
  self.titleImage = resourceMan:get('res/title.png', Image, {
    engine=engine, 
    file='res/title.png'
  })
  self.font = resourceMan:get('res/textbold-9x15.png', Image, {
    engine=engine, 
    file='res/textbold-9x15.png', 
    tilew=9, tileh=15
  })

  self.choices = {
    {
      label = 'Start',
      percentX = 30
    },
    {
      label = 'Quit',
      percentX = 60,
      quit = true
    }
  }

  self.control = {
    up = function()
      self.choiceIndex = (self.choiceIndex - 1) % #self.choices
    end,
    down = function()
      self.choiceIndex = (self.choiceIndex + 1) % #self.choices
    end,
    enter = function()
      self.choice = self.choices[self.choiceIndex+1]
      self.engine:stop()
    end,
    none = function() end
  }

  self.keys = setmetatable({
    A = 'up',
    D = 'down',
    Left = 'up',
    Right = 'down',
    Return = 'enter'
  }, {
    __index = function(t, k) return 'none' end
  })

  self.choiceIndex = 0
end


function StartMenu:getChoice()
  local vw, vh = self.engine:getLogicalSize()
  local textY = 165

  self.engine:run{
    redraw = function()
      -- clear
      self.engine:setColor(255, 255, 255, 255)
      self.engine:clear()

      -- draw background
      self.titleImage:drawWhole(0, 0)

      -- draw choices
      for i, choice in ipairs(self.choices) do
        local textX = (choice.percentX / 100 * vw) // 1

        self.font:drawText(choice.label, textX, textY, 100)
        if (i - 1) == self.choiceIndex then
          -- draw choice marker
          self.engine:setColor(255, 0, 127, 255)
          self.engine:fillRect(textX - 18, textY, 15, 15)
        end
      end

    end,

    keydown = function(key)
      self.control[self.keys[key]]()
    end
  }

  if self.choice then
    return self.choice.file, self.choice.quit
  else
    return nil, true
  end
end


return StartMenu

