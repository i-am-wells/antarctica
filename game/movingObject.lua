local math = require 'math'

local Class = require 'class'
local MovingObject = Class()

function MovingObject:setStepSize(stepsize)
    self.stepsize = stepsize
    
    if self.velx > 0 then
        self:setVelocity(self.stepsize, nil)
    elseif self.velx < 0 then
        self:setVelocity(-self.stepsize, nil)
    end

    if self.vely > 0 then
        self:setVelocity(nil, self.stepsize)
    elseif self.vely < 0 then
        self:setVelocity(nil, -self.stepsize)
    end
end


function MovingObject:turn(direction)
    self.direction = direction
end


function MovingObject:updateDirection()

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


function MovingObject:isFacing(other)
    self:getLocation()
    other:getLocation()

    local testX, testY
    if self.direction == 'north' then
        testX = self.x + self.bbox.x + self.bbox.w // 2
        testY = self.y + self.bbox.y 

        return ((math.abs(testY - (other.y + other.bbox.y + other.bbox.h)) < 5) 
            and (testX >= other.x + other.bbox.x)
            and (testX < other.x + other.bbox.x + other.bbox.w)
        )
    elseif self.direction == 'south' then
        testX = self.x + self.bbox.x + self.bbox.w // 2
        testY = self.y + self.bbox.y + self.bbox.h
    
        return ((math.abs(other.y + other.bbox.y - testY) < 5)
            and (testX >= other.x + other.bbox.x)
            and (testX < other.x + other.bbox.x + other.bbox.w)
        )
    elseif self.direction == 'east' then
        testX = self.x + self.bbox.x + self.bbox.w
        testY = self.y + self.bbox.y + self.bbox.h // 2

        return ((math.abs(other.x + other.bbox.x - testX) < 5)
            and (testY >= other.y + other.bbox.y)
            and (testY < other.y + other.bbox.y + other.bbox.h)
        )
    elseif self.direction == 'west' then
        testX = self.x + self.bbox.x - 1
        testY = self.y + self.bbox.y + self.bbox.h // 2
        return ((math.abs(testX - (other.x + other.bbox.x + other.bbox.w)) < 5)
            and (testY >= other.y + other.bbox.y)
            and (testY < other.y + other.bbox.y + other.bbox.h)
        )
    end
end

return MovingObject
