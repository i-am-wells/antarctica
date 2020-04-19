local ant = require 'antarctica'
ant.init()

local Image = require 'image'
local Engine = require 'engine'
local MainMenuContext = require 'game2.MainMenuContext'
local GameContext = require 'game2.GameContext'

local resDirectory = __rootdir..'/res'

-- calculate view size
local vw, vh, logicalScale
do
  local dispX, dispY, dispW, dispH = ant.engine.getDisplayBounds()

  -- aim to fit at most 30 tiles horizontally
  local targetScale = dispW / 16 / 30 // 1 + 1
  vw = dispW // targetScale
  vh = dispH // targetScale
  logicalScale = 1
end

do
  -- Create a window.
  local engine = Engine{
    title = 'Game', 
    w = vw * logicalScale, 
    h = vh * logicalScale, 
    windowflags = ant.engine.fullscreendesktop
  }
  -- Render everything normally but scale the canvas to match the window.
  engine:setLogicalSize(vw, vh)
  engine.vw = vw
  engine.vh = vh
  engine:setColor(255, 255, 255, 255) -- white background
    
  local font9x15 = Image{
    engine = engine,
    file=resDirectory..'/textbold-9x15.png', 
    tilew=9,
    tileh=15
  }
 
  -- State machine for coordinating game, menu, and credits.
  local states
  states = {
    menu = function()
      local menu = MainMenuContext{
        engine = engine,
        font = font9x15,
      }

      -- Run the menu.
      menu:takeControlFrom()

      -- quit if the user wants to quit
      if menu:shouldQuit() then
        return nil
      end

      return states.game, menu:saveFileName()
    end,

    game = function(saveFileName)
      -- start game
      local game = GameContext{
        engine = engine,
        font = font9x15,
        resDirectory = resDirectory,
        saveFileName = saveFileName,
      }

      game:takeControlFrom()

      if game:shouldShowCredits() then
        return states.credits
      elseif game:shouldQuitToMenu() then
        return states.menu
      elseif game:shouldQuitToOs() then
        return nil
      end
    end,

    credits = function()
      print('TODO credits here')
      return states.menu
    end
  }

  -- Each state returns the next state
  local state, args = states.menu, nil
  while state do
    state, args = state(args)
  end
end

ant.quit()
