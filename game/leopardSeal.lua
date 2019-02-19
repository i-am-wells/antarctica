local ant = require 'antarctica'

local Class = require 'class'
local Image = require 'image'
local AnimatedObject = require 'animatedObject'
local Sound = require 'sound'
local AudioSource = require 'audioSource'


local MovingObject = require 'game.movingObject'
local resourceInfo = require 'game.resourceInfo'
local util = require 'game.util'
local TextBar = require 'game.textBar'

local LeopardSeal = Class(AnimatedObject, AudioSource, MovingObject)

LeopardSeal.imageFile = 'res/leopardseal.png'

-- TODO fix
local tileW, tileH = 16, 16

LeopardSeal.sprites = {
    walk = {
        north = {
            {tx=5, ty=0, tw=32, th=48, bbox={x=0, y=0, w=32, h=32}, offX=0, offY=0},
            {tx=5, ty=1, tw=32, th=48, bbox={x=0, y=0, w=32, h=32}, offX=0, offY=0}
        },
        south = {
            {tx=4, ty=0, tw=32, th=48, bbox={x=0, y=0, w=32, h=32}, offX=0, offY=-16},
            {tx=4, ty=1, tw=32, th=48, bbox={x=0, y=0, w=32, h=32}, offX=0, offY=-16}
        },
        east = {
            {tx=1, ty=0, tw=64, th=32, bbox={x=0, y=-16, w=32, h=32}, offX=-32, offY=-16},
            {tx=1, ty=1, tw=64, th=32, bbox={x=0, y=-16, w=32, h=32}, offX=-32, offY=-16}
        },
        west = {
            {tx=0, ty=0, tw=64, th=32, bbox={x=0, y=-16, w=32, h=32}, offX=0, offY=-16},
            {tx=0, ty=1, tw=64, th=32, bbox={x=0, y=-16, w=32, h=32}, offX=0, offY=-16}
        },

        timing = {
            div = 8,
            mod = 2,
            [0] = 1,
            [1] = 2
        }
    },
    attack = {
        north = {
            {tx=5, ty=2, tw=32, th=48, bbox={x=0, y=0, w=32, h=32}, offX=0, offY=-4},
            {tx=5, ty=1, tw=32, th=48, bbox={x=0, y=0, w=32, h=32}, offX=0, offY=-8},
            {tx=5, ty=0, tw=32, th=48, bbox={x=0, y=0, w=32, h=32}, offX=0, offY=0},
        },
        south = {
            {tx=4, ty=2, tw=32, th=48, bbox={x=0, y=0, w=32, h=32}, offX=0, offY=-12},
            {tx=4, ty=1, tw=32, th=48, bbox={x=0, y=0, w=32, h=32}, offX=0, offY=-8},
            {tx=4, ty=0, tw=32, th=48, bbox={x=0, y=0, w=32, h=32}, offX=0, offY=-16},
        },
        east = {
            {tx=1, ty=2, tw=64, th=32, bbox={x=0, y=-16, w=32, h=32}, offX=-28, offY=-16},
            {tx=1, ty=1, tw=64, th=32, bbox={x=0, y=-16, w=32, h=32}, offX=-24, offY=-16},
            {tx=1, ty=0, tw=64, th=32, bbox={x=0, y=-16, w=32, h=32}, offX=-32, offY=-16},
        },
        west = {
            {tx=0, ty=2, tw=64, th=32, bbox={x=0, y=-16, w=32, h=32}, offX=-4, offY=-16},
            {tx=0, ty=1, tw=64, th=32, bbox={x=0, y=-16, w=32, h=32}, offX=-8, offY=-16},
            {tx=0, ty=0, tw=64, th=32, bbox={x=0, y=-16, w=32, h=32}, offX=0, offY=-16},
        },
        timing = {
            div = 4,
            mod = 8,
            [0] = 1,
            [1] = 2,
            [2] = 2,
            [3] = 3,
            [4] = 3,
            [5] = 3,
            [6] = 3,
            [7] = 3
        }
    }
}


function LeopardSeal:init(options)    
    self.direction = options.direction or 'south'
    self.movement = options.movement or 'walk'
    self.stepsize = options.stepsize or 3

    self.engine = options.resourceMan:get('engine')

    self.data = options.data

    self.resourceMan = options.resourceMan

    -- parent init
    AnimatedObject.init(self, options)
    AudioSource.init(self, options)

    self:setMass(20)

    self.hp = 10
    self.maxHp = 10

    self:walk()
end


function LeopardSeal:oncollision(other)
    if (other == ant.tilemap.getCameraObject(self._tilemap)) and (self.movement ~= 'attack') then
        
        if self.updateCounter > 32 then
            -- fight!
            other:fight()

            self:move(-self.velx, -self.vely)

            self.target = other
            self:attack()

        end
    end
end


function LeopardSeal:onupdate()
    -- Update sprite if necessary
    self:updateSprite()

    -- TODO chase hero or other penguins

    local hero = ant.tilemap.getCameraObject(self._tilemap)

    hero:getLocation()
    self:getLocation()

    local dx, dy = (self.x - hero.x), (self.y - hero.y)
    if self.movement ~= 'attack' then
        local baseSpeed = 1
        if self.frameNumber == 0 then
            baseSpeed = 1
        elseif self.frameNumber == 1 then
            baseSpeed = 3
        end

        local vx, vy = 0, 0
        if dx > 0 then 
            vx = -baseSpeed
        elseif dx < 0 then 
            vx = baseSpeed
        end
        if dy > 0 then 
            vy = -baseSpeed
        elseif dy < 0 then 
            vy = baseSpeed
        end
        self:setVelocity(vx, vy)
    elseif self.updateCounter == 32 then
        self:walk()
    elseif (self.updateCounter >= 4) and (self.updateCounter < 24) then
        local sx, sy = self:getScreenLocation(self.engine.vw, self.engine.vh)
        
        if self.missed then
            -- draw "miss"
            self.image:draw(0, 104, 24, 8, sx, sy, 24, 8)
        else
            -- draw "chomp"
            self.image:draw(0, 96, 24, 8, sx, sy, 24, 8)
        end
    end
    self:turn(util.getOppositeDirection(dx, dy))

end

function LeopardSeal:onInteract(other)
    local engine = self.resourceMan:get('engine')

    self.interacter = other

    if other.moveDirectionStack then
        other.moveDirectionStack = {}
    end
    
    -- Open speech bar
    self.textBar = TextBar{
        resourceMan = self.resourceMan,
        text = self.data.says,
        name = self.data.name
    }

    self.textBar:open(other.controller)

    self.speechCounter = 300
end


function LeopardSeal:walk()
    self.movement = 'walk'
    self:setStepSize(2)
    self.updateCounter = 0
    self:setMass(5)
end


function LeopardSeal:attack()
    self.movement = 'attack'
    self:setStepSize(0)
    self.updateCounter = 0
    self:setMass(20)

    if self:isFacing(self.target) and self:isTouching(self.target) then
        -- TODO calculate damage
        self.target:takeDamage(2)
        self.missed = false
    else
        self.missed = true
    end
end


function LeopardSeal:playSound(sound, opt)
    local sx, sy = self:getScreenLocation(self.engine.vw, self.engine.vh)
    AudioSource.playSound(self, sound, self.x - sx + self.engine.vw // 2, self.y - sy + self.engine.vh // 2, opt)
end

function LeopardSeal:updateVolumeStereo()
    local sx, sy = self:getScreenLocation(self.engine.vw, self.engine.vh)
    AudioSource.updateVolumeStereo(self, self.x - sx + self.engine.vw // 2, self.y - sy + self.engine.vh // 2)
end

return LeopardSeal


