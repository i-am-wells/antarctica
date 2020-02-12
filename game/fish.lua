local math = require 'math'

local ant = require 'antarctica'

local Class = require 'class'
local AnimatedObject = require 'animatedObject'
local util = require 'game.util'

local Fish = Class(AnimatedObject)

Fish.sprites = {
  rest = {
    east = {{tx=1, ty=28, tw=16, th=8, bbox={x=0, y=0, w=16, h=8}, offX=0, offY=0}},
    south = {{tx=1, ty=28, tw=16, th=8, bbox={x=0, y=0, w=16, h=8}, offX=0, offY=0}},
    north = {{tx=1, ty=28, tw=16, th=8, bbox={x=0, y=0, w=16, h=8}, offX=0, offY=0}},
    west = {{tx=2, ty=28, tw=16, th=8, bbox={x=0, y=0, w=16, h=8}, offX=0, offY=0}},
    timing = {
      div = 256,
      mod = 1,
      [0] = 1
    }
  },
  swim = {
    south = {
      {tx=1, ty=14, tw=8, th=16, bbox={x=0,y=0,w=8,h=16}, offX=0, offY=0},
      {tx=1, ty=15, tw=8, th=16, bbox={x=0,y=0,w=8,h=16}, offX=0, offY=0}
    },
    north = {
      {tx=0, ty=14, tw=8, th=16, bbox={x=0,y=0,w=8,h=16}, offX=0, offY=0},
      {tx=0, ty=15, tw=8, th=16, bbox={x=0,y=0,w=8,h=16}, offX=0, offY=0}
    },
    east = {
      {tx=1, ty=29, tw=16, th=8, bbox={x=0, y=0, w=16, h=8}, offX=0, offY=0},
      {tx=1, ty=30, tw=16, th=8, bbox={x=0, y=0, w=16, h=8}, offX=0, offY=0}
    },
    west = {
      {tx=2, ty=29, tw=16, th=8, bbox={x=0, y=0, w=16, h=8}, offX=0, offY=0},
      {tx=2, ty=30, tw=16, th=8, bbox={x=0, y=0, w=16, h=8}, offX=0, offY=0}
    },

    timing = {
      div = 4,
      mod = 2,
      [0] = 1,
      [1] = 2
    }
  }
}

Fish.imageFile = 'res/spritesnew-16x16.png'


function Fish:init(options)

  self.stepsize = 3
  self.movement = 'rest'

  if math.random() < 0.5 then
    self.direction = 'east'
  else
    self.direction = 'west'
  end


  AnimatedObject.init(self, options)

  self:burst()

  self:on{
    update = function(_self)
      self:updateSprite()

      if self.updateCounter > self.burstDuration then
        self:burst()
      elseif self.updateCounter >= (self.burstDuration * 0.6 // 1) then
        self:setVelocity(self.velx // 2, self.vely // 2)
        self:updateDirection()
      end
    end,

    wallbump = function(_self, direction)
      local vx, vy = nil, nil
      if self.velx > 0 and (direction & ant.tilemap.bumpwestflag) then
        vx = -self.velx
      elseif self.velx < 0 and (direction & ant.tilemap.bumpeastflag) then
        vx = -self.velx
      end

      if self.vely > 0 and (direction & ant.tilemap.bumpnorthflag) then
        vy = -self.vely
      elseif self.vely < 0 and (direction & ant.tilemap.bumpsouthflag) then
        vy = -self.vely
      end

      self:setVelocity(vx, vy)
      self:updateDirection()
    end,
  }
end


function Fish:updateDirection()
  self.direction = util.getDirection(self.velx, self.vely)
  if (self.velx == 0) and (self.vely == 0) then    
    self.movement = 'rest'
  else
    self.movement = 'swim'
  end
end


function Fish:burst()
  -- Random direction
  local vx = (math.random() * 5 // 1) - 2
  local vy = (math.random() * 5 // 1) - 2

  self.burstDuration = 50 + math.random() * 15 // 1

  self:setVelocity(vx, vy)
  self:updateDirection()

  self.updateCounter = 0
end

return Fish

