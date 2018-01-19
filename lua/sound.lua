
local ant = require 'antarctica'

local class = require 'class'

local Sound = class.base()

-- TODO
-- ant.sound.read
-- ant.sound.play
-- ant.sound.queue

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


function Sound:define(key, starttime, duration)
    -- TODO check if start/duration are within sound bounds?
    self.segments[key] = {start = starttime, duration = duration}
end


function Sound:getSegment(key, dur)
    if type(key) == 'string' then
        local seg = self.segments[key]
        if seg then
            return seg.start, seg.duration
        else
            return 0, nil
        end
    else
        return key, dur
    end
end


--[[function Sound:play(start, duration)
    local startTime, duration = self:getSegment(start, duration)
    ant.sound.play(self._sound, startTime, duration)
end--]]

function Sound:play(options)
    local options = options or {}
    local channel = options.channel or -1
    local nloops = options.nloops or 0
    if options.loop == true then
        nloops = -1
    end
    ant.sound.play(self._sound, channel, nloops)
end


--[[function Sound:queue(start, duration)
    local startTime, duration = self:getSegment(start, duration)
    ant.sound.queue(self._sound, startTime, duration)
end--]]


return Sound

