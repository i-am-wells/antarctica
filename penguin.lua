
local class = require 'class'
local Object = require 'object'

local Penguin = class.deriving(Object)

function Penguin:init(options)
    -- Set up sprite options
    options.tx = options.tx or 10
    options.ty = options.ty or 0
    options.tw = options.tw or 16
    options.th = options.th or 32
    options.animation_count = options.animation_count or 1
    options.animation_period = options.animation_period or 1

    Object.init(self, options)

    -- Penguin's walking velocity
    self.stepsize = 2


    -- Used for looking up which sprite to use for each direction the penguin
    -- can face.
    self.walkinfo = {
        north = { tx = 11, ty = 0 },
        south = { tx = 10, ty = 0 },
        east = { tx = 12, ty = 0 },
        west = { tx = 13, ty = 0 }
    }
    -- For the walking animation
    self.walkY = { 0, 1, 0, 2 }
end


-- Turns the penguin to face north, south, east, or west
function Penguin:turn(direction)
    self.direction = direction
    local winfo = self.walkinfo[direction]
    self:setsprite(winfo.tx, winfo.ty)
end

-- Update the penguin's sprite to create the walking animation
function Penguin:setspriteY(count)
    local frame = (count // 4) % 4
    local winfo = self.walkinfo[self.direction]
    self:setsprite(winfo.tx, winfo.ty + self.walkY[frame+1])
end

function Penguin:updateDirection()
    if self.direction == 'north' then
        if self.vely > 0 then
            self:turn('south')
        elseif self.vely == 0 then
            if self.velx > 0 then
                self:turn('east')
            elseif self.velx < 0 then
                self:turn('west')
            end
        end
    elseif self.direction == 'south' then
        if self.vely < 0 then
            self:turn('north')
        elseif self.vely == 0 then
            if self.velx > 0 then
                self:turn('east')
            elseif self.velx < 0 then
                self:turn('west')
            end
        end
    elseif self.direction == 'east' then
        if self.velx < 0 then
            self:turn('west')
        elseif self.velx == 0 then
            if self.vely > 0 then
                self:turn('south')
            elseif self.vely < 0 then
                self:turn('north')
            end
        end
    elseif self.direction == 'west' then
        if self.velx > 0 then
            self:turn('east')
        elseif self.velx == 0 then
            if self.vely > 0 then
                self:turn('south')
            elseif self.vely < 0 then
                self:turn('north')
            end
        end
    end
end

function Penguin:walk(direction)
    local velx = {
        east = self.stepsize,
        west = -self.stepsize
    }
    local vely = {
        north = -self.stepsize,
        south = self.stepsize
    }
    self:setVelocity(velx[direction], vely[direction])
    self:updateDirection()
end


function Penguin:interact(map)
    local mx, my = self:getTileLocation()

    if self.direction == 'north' then
        map:runInteractCallback(self.layer, mx, my, self)
    elseif self.direction == 'south' then
        map:runInteractCallback(self.layer, mx, my + 2, self)
    elseif self.direction == 'east' then
        map:runInteractCallback(self.layer, mx - 1, my, self)
    elseif self.direction == 'east' then
        map:runInteractCallback(self.layer, mx + 1, my, self)
    end
end

return Penguin

