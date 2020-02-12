local ant = require 'antarctica'

local Class = require 'class'
local Engine = require 'engine'

--[[
local ObjectEditor = require 'devtools.objectEditor'
local MapEditor = require 'devtools.mapEditor'
--]]

local ModeMenu = require 'devtools.modeMenu'

local DevSession = Class()



function DevSession:init(opt)
  -- should have a Game object
  self.game = opt.game

  -- Find all original handlers to be restored after dev session closed
  self.origEngineHandlers = {}
  for eventName, _ in pairs(Engine.eventkeymap) do
    local handler = self.game.engine['on'..eventName]
    if handler then
      print(eventName, handler)
      self.origEngineHandlers[eventName] = handler
    end
  end


  -- Show menu for modes
  local modeMenu = ModeMenu{devSession = self}
  modeMenu:open(self.game)

  --[[
  --  set up new handlers
  self.engine:on{
    -- keep original redraw

    mousebuttondown = function(x, y, button)
    -- TODO
    end,

    mousebuttonup = function(x, y, button)

    end,

    mousemotion = function(x, y, dx, dy, state)

    end,

    keydown = function(key, mod, isRepeat)

    end,

    keydown = function(key, mod, isRepeat)

    end,
    }
    --]]
  end

  function DevSession:close()
    -- First, overwrite all handlers
    local emptyHandlers = {}
    local noop = function() end
    for eventName, _ in pairs(Engine.eventkeymap) do
      emptyHandlers[eventName] = noop
    end
    self.game.engine:on(emptyHandlers)

    -- now restore original handlers
    self.game.engine:on(self.origEngineHandlers)
  end

  -- TODO here for now until I find a better place for it
  function DevSession:screenToWorld(screenX, screenY)

    -- get world position of upper left corner of screen
    local cx, cy = ant.tilemap.getCameraLocation(self.game.map._tilemap, self.game.engine.vw, self.game.engine.vh)

    return screenX + cx, screenY + cy
  end

  --[[
  local recursiveCopyTable
  recursiveCopyTable = function(t)
  if type(t) == 'table' then
  local tCopy = {}
  for k,v in pairs(t) do
  tCopy[k] = recursiveCopyTable(v)
  end
  return tCopy
  else
  return t
  end
  --]]


  function DevSession:dumpState(file)
    -- TODO be more systematic about this

  end

  return DevSession
