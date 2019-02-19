
local ant = require 'antarctica'

local Class = require 'class'

local Sound = Class()


function Sound:init(options)
    options = options or {}
    if options.file then
        self._sound = ant.sound.read(options.file)
        self.segments = {}
        if not self._sound then
            error('Failed to open '..options.file)
        end
    else
        error('Sound object must be initialized with a "file" argument')
    end
end

function Sound:play(options)
    local options = options or {}
    local channel = options.channel or -1
    local nloops = options.nloops or 0
    if options.loop == true then
        nloops = -1
    end
    local duration = options.duration or -1
    ant.sound.play(self._sound, channel, nloops, duration)
end

return Sound

