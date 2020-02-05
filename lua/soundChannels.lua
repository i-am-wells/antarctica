local ant = require 'antarctica'

local Class = require 'class'

local SoundChannels = Class()

function SoundChannels:init(options)
    self.initialNumChannels = options.initialNumChannels or 1
    self.sourceMap = options.sourceMap or {}
   
    -- keep stack of newly available channels
    self.freedStack = {}

    self:reallocateChannels()
end

function SoundChannels:addSource(source)
    if #self.freedStack > 0 then
        source.channel = table.remove(self.freedStack)
        self.sourceMap[source.channel] = source 
    else
        table.insert(self.sourceMap, source)
        source.channel = #self.sourceMap
    end
end

-- Assumes all "sources" inherit from AudioSource.
function SoundChannels:addSources(sources)
    for i, source in ipairs(sources) do
        self:addSource(source)
    end
end

function SoundChannels:removeSource(source)
    -- look up and remove
    self.sourceMap[source.channel] = nil
    table.insert(self.freedStack, source.channel)
    source.channel = nil
end

function SoundChannels:removeSources(sources)
    for i, source in ipairs(sources) do
        self:removeSource(source)
    end
end

function SoundChannels:reallocateChannels()
    if self.numChannels ~= #self.sourceMap then
        -- Make sure there are enough channels
        ant.sound.reallocateChannels(#self.sourceMap)
        self.numChannels = #self.sourceMap
    end
end

return SoundChannels
