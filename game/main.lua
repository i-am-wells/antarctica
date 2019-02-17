local ant = require 'antarctica'

local Engine = require 'engine'
local ResourceManager = require 'resourceManager'

local Game = require "game.game"
local StartMenu = require "game.startMenu"


-- calculate view size
local vw, vh, logicalScale
do
    local dispX, dispY, dispW, dispH = ant.engine.getDisplayBounds()
    
    -- aim to fit at most 30 tiles horizontally
    local targetScale = dispW / 16 / 30 // 1 + 1
    --local targetScale = dispH / 16 / 16 // 1
    vw = dispW // targetScale
    vh = dispH // targetScale
    logicalScale = 1
end

-- Create engine

-- Create a window. "setlogicalsize" lets us render everything normally but
-- will scale the canvas to match the window.
local engine = Engine{
    title = 'Game', 
    w = vw * logicalScale, 
    h = vh * logicalScale, 
    windowflags = ant.engine.fullscreendesktop
}
engine:setLogicalSize(vw, vh)
engine.vw = vw
engine.vh = vh
engine:setColor(255, 255, 255, 255) -- white background


-- Create resource manager
local res = ResourceManager()
res:set('engine', engine)


-- State machine for coordinating game, menu, and credits.

local states
states = {
    menu = function()
        local menu = StartMenu(engine, res)

        -- Show the menu
        local saveFileName, quit = menu:getChoice()
        
        -- quit if the user wants to quit
        if quit then
            return nil
        end

        local savedGame
        if saveFileName then
            -- TODO try to load saved game
            return states.game, saveFileName
        else
            -- start new game
            return states.game, nil
        end
    end,

    game = function(saveFileName)
        -- start game
        local theGame = Game{
            engine = engine,
            saveFileName = saveFileName,
            resourceMan = res
        }

        local isSaved, isFinished = theGame:run()

        local isSaved, isFinished
        if isFinished then
            return states.credits, nil
        end

        if not isSaved then
            -- TODO prompt save
        end

        return nil,nil
        --return states.menu, nil
    end,

    credits = function()
        -- TODO end credits
        return states.menu, nil
    end
}


-- Each state returns the next state
local state, args = states.menu, nil
while state do
    state, args = state(args)
end

