local math = require 'math'

local ant = require 'antarctica'
local Class = require 'class'

local AudioSource = Class()


AudioSource.volume = 1

AudioSource.audibleRadius = 320


function AudioSource:init(opt)
    self.channel = opt.channel or nil

    self.sameSideCoef = self.sameSideCoef or opt.sameSideCoef
    self.oppositeSideCoef = self.oppositeSideCoef or opt.oppositeSideCoef

    self.volume = self.volume or opt.volume

    self.x = self.x or opt.x
    self.y = self.y or opt.y
end


function AudioSource:calculateVolumeStereo(listenerX, listenerY)
    local dx, dy = ((self.x - listenerX) / self.audibleRadius), ((self.y - listenerY) / self.audibleRadius)

    local base = math.exp(1)
    local sameVol = math.log(base / ((base - 1) * (dx * dx + dy * dy) + 1), base)
    local oppVol = math.log(base / ((base - 1) * (4 * dx * dx + dy * dy) + 1), base)

    sameVol, oppVol = math.max(0, sameVol), math.max(0, oppVol)

    if dx >= 0 then
        return (self.volume * oppVol), (self.volume * sameVol)
    else
        return (self.volume * sameVol), (self.volume * oppVol)
    end
end


function AudioSource:calculateVolumeMono(listenerX, listenerY)
    local dx, dy = ((self.x - listenerX) / self.audibleRadius), ((self.y - listenerY) / self.audibleRadius)

    local base = 2
    local vol = math.log(base / ((base - 1) * (dx * dx + dy * dy) + 1), base)

    return self.volume * vol
end


function AudioSource:playSound(sound, listenerX, listenerY, opt)
    opt = opt or {}
    self:updateVolumeStereo(listenerX, listenerY)
    --print('play sound: '..self.channel)
    sound:play{channel = self.channel, loop=opt.loop, duration=opt.duration}
end


function AudioSource:updateVolumeStereo(listenerX, listenerY)
    -- Set left and right volume
    --print(listenerX, listenerY)
    -- TODO fix
    local l, r = self:calculateVolumeStereo(listenerX, listenerY)
    ant.sound.setChannelVolume(self.channel, l, r)

end


return AudioSource

