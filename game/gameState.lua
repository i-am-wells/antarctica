
local Class = require "class"

local GameState = Class()

function GameState:init(opt)
    -- consider hero state, state of each object, time/date in game, time irl
    -- story variables
    opt = opt or {}

    self.objects = opt.objects or {}
end

function GameState:read(filename)
    -- TODO yaml or copy table
end

function GameState:write(filename)
    -- TODO yaml
end

return GameState

