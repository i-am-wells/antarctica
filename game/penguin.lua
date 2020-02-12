local math = require 'math'
local ant = require 'antarctica'

local Class = require 'class'
local Image = require 'image'
local AnimatedObject = require 'animatedObject'
local Sound = require 'sound'
local AudioSource = require 'audioSource'

local MovingObject = require 'game.movingObject'
local resourceInfo = require 'game.resourceInfo'
local util = require 'game.util'
local SpeechBubble = require 'game.speechBubble'
local TextBar = require 'game.textBar'

local Penguin = Class(AnimatedObject, AudioSource, MovingObject)

local footstepSoundFile = 'res/sound/footstep0.wav'

Penguin.imageFile = 'res/penguin.png'

-- TODO fix
local tileW, tileH = 16, 16

-- accessories
Penguin.accessories = {
  backpack = {x=0, y=128, w=128, h=128},
  minerHat = {x=128, y=0, w=64, h=96},
  brownApron = {x=192, y=0, w=64, h=96},
  whiteApron = {x=256, y=0, w=64, h=96},
  grandma = {x=128, y=96, w=64, h=96},
  mayorHat = {x=192, y=96, w=64, h=96},
  policeHat = {x=128, y=192, w=64, h=96}
}

Penguin.standingBox = {x=1, y=1, w=14, h=14}
Penguin.slidingBox = {x=-15, y=0, w=14, h=14}
local sp = function(tx, ty, mode, offX, offY)
  local t = {tx=tx, ty=ty, offX=offX, offY=offY}
  if mode == 'walk' then
    t.bbox = Penguin.standingBox
    t.tw = 16
    t.th = 32
  elseif mode == 'slide' then
    t.bbox = Penguin.slidingBox
    t.tw = 32
    t.th = 16
  end
  return t
end


Penguin.sprites = {
  stand = {
    north = {sp(1, 0, 'walk', 0, -16)},
    south = {sp(0, 0, 'walk', 0, -16)},
    east = {sp(2, 0, 'walk', 0, -16)},
    west = {sp(3, 0, 'walk', 0, -16)},
    timing = {div=1, mod=1, [0]=1} 
  },
  walk = {
    north = {
      sp(1, 0, 'walk', 0, -16),
      sp(1, 1, 'walk', 0, -16),
      sp(1, 0, 'walk', 0, -16),
      sp(1, 2, 'walk', 0, -16)
    },
    south = {
      sp(0, 0, 'walk', 0, -16),
      sp(0, 1, 'walk', 0, -16),
      sp(0, 0, 'walk', 0, -16),
      sp(0, 2, 'walk', 0, -16)
    },
    east = {
      sp(2, 0, 'walk', 0, -16),
      sp(2, 1, 'walk', 0, -16),
      sp(2, 0, 'walk', 0, -16),
      sp(2, 2, 'walk', 0, -16)
    },
    west = {
      sp(3, 0, 'walk', 0, -16),
      sp(3, 1, 'walk', 0, -16),
      sp(3, 0, 'walk', 0, -16),
      sp(3, 2, 'walk', 0, -16)
    },

    timing = {
      mod = 4,
      div = 4,
      [0] = 2,
      [1] = 3,
      [2] = 4,
      [3] = 1
    }
  },

  slide = {
    north = {
      {tx=5, ty=0, tw=16, th=32, bbox={x=0, y=0, w=16, h=16}, offX=0, offY=-8},
      {tx=5, ty=1, tw=16, th=32, bbox={x=0, y=0, w=16, h=16}, offX=0, offY=-8}
    },
    south = {
      {tx=4, ty=0, tw=16, th=32, bbox={x=0, y=0, w=16, h=16}, offX=0, offY=-8},
      {tx=4, ty=1, tw=16, th=32, bbox={x=0, y=0, w=16, h=16}, offX=0, offY=-8}
    },
    east = {
      {tx=3, ty=0, tw=32, th=16, bbox={x=0, y=0, w=16, h=16}, offX=-8, offY=0},
      {tx=3, ty=1, tw=32, th=16, bbox={x=0, y=0, w=16, h=16}, offX=-8, offY=0}
    },
    west = {
      {tx=3, ty=2, tw=32, th=16, bbox={x=0, y=0, w=16, h=16}, offX=-8, offY=0},
      {tx=3, ty=3, tw=32, th=16, bbox={x=0, y=0, w=16, h=16}, offX=-8, offY=0}
    },

    timing = {
      div = 1,
      mod = 1,
      [0] = 1,
      [1] = 2
    }
  },

  peck = {
    north = {
      sp(1, 3, 'walk', 0, -20),
      sp(1, 0, 'walk', 0, -16)
    },
    south = {
      sp(0, 3, 'walk', 0, -12),
      sp(0, 0, 'walk', 0, -16)
    },
    east = {
      sp(2, 3, 'walk', 4, -16),
      sp(2, 0, 'walk', 0, -16)
    },
    west = {
      sp(3, 3, 'walk', -4, -16),
      sp(3, 0, 'walk', 0, -16)
    },
    timing = {
      div=4, 
      mod=8, 
      [0] = 1,
      [1] = 2,
      [2] = 2,
      [3] = 2,
      [4] = 2,
      [5] = 2,
      [6] = 2,
      [7] = 2,
    }
  },

  swim = {
    north = {
      {tx=5, ty=0, tw=16, th=32},
      {tx=5, ty=1, tw=16, th=32}
    },
    south = {
      {tx=4, ty=0, tw=16, th=32},
      {tx=4, ty=1, tw=16, th=32}
    },
    east = {
      {tx=3, ty=0, tw=32, th=16},
      {tx=3, ty=1, tw=32, th=16}
    },
    west = {
      {tx=3, ty=2, tw=32, th=16},
      {tx=3, ty=3, tw=32, th=16}
    }
  }
}


local footprints = {

}


function Penguin:init(options)    
  self.direction = options.direction or 'south'
  self.movement = options.movement or 'stand'
  self.stepsize = options.stepsize or 2

  self.engine = options.resourceMan:get('engine')

  self.data = options.data

  -- TODO load sounds

  local file = footstepSoundFile
  self.footstepSound = options.resourceMan:get(file, Sound, {
    file = file
  })

  self.resourceMan = options.resourceMan

  -- parent init
  AnimatedObject.init(self, options)
  AudioSource.init(self, options)

  -- Add accessory
  if self.data.accessory then
    -- own image: blank
    local origImage = self.image
    self.image = options.resourceMan:get(Penguin.imageFile..self.data.name, Image, {
      engine = self.engine,
      w = 128, h = 128
    })

    local acc = self.data.accessory
    origImage:targetImage(self.image)
    origImage:draw(0, 0, 128, 128, 0, 0, 128, 128)
    origImage:draw(acc.x, acc.y, acc.w, acc.h, 0, 0, acc.w, acc.h)
    origImage:targetImage(nil)

    self:setImage(self.image)
  end

  self.footprints = {}
end


function Penguin:addFootprint()
  self:getLocation()
  -- TODO
end


function Penguin:onupdate()
  -- Update sprite if necessary
  self:updateSprite()
  self:updateVolumeStereo()

  if self.fightMenu then
    if self:distanceTo(self.interactTarget) > 108 then
      self.fightMenu:close()
      self.fightMenu = nil
    end
  end

  -- Slide motion
  if self.movement == 'slide' then
    if self.updateCounter == 20 then
      self:setStepSize(2)
    elseif self.updateCounter == 32 then
      self:setStepSize(1)
    elseif self.updateCounter == 40 then
      self:setStepSize(0)
    end
  elseif self.movement == 'walk' then
    local wstep = (self.updateCounter // 8) % 4
    if wstep == 0 then
      --self:playSound(self.footstepSound)
    end
  elseif self.movement == 'peck' then
    if self.updateCounter == 32 then
      self:stand()
    end
  end

  if self.textBar and self.textBar.isOpen then
    -- face speaker
    self:getLocation()
    self.interacter:getLocation()

    self:turn(util.getOppositeDirection(self.x - self.interacter.x, self.y - self.interacter.y))
  end
end


function Penguin:onInteract(other)
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



  local inhale = self.resourceMan:get('res/sound/inhale.wav', Sound, {
    file='res/sound/inhale.wav'
  })
  self:playSound(inhale, {loop=true})
end


function Penguin:stand()
  if (self.velx ~= 0) or (self.vely ~= 0) then
    self:walk()
  else
    self.movement = 'stand'
    self:setStepSize(2)
    self.updateCounter = 0

  end
end


function Penguin:walk()
  self.movement = 'walk'
  self:setStepSize(2)
  self.updateCounter = 0
end


function Penguin:dive()
  self.movement = 'slide'
  self.setStepSize(1)
  self.updateCounter = 0
end


function Penguin:slide()
  self.movement = 'slide'
  self:setStepSize(4)
  self.updateCounter = 0

  -- Slide n, s, e, or w only
  if self.direction == 'north' or self.direction == 'south' then
    self:setVelocity(0, nil)
  else
    self:setVelocity(nil, 0)
  end
end


function Penguin:peck()
  if self.movement ~= 'peck' then
    self.movement = 'peck'
    self:setStepSize(0)
    self.updateCounter = 0
  end
end


function Penguin:takeDamage(damage)
  self.hp = math.max(self.hp - damage, 0)
end


function Penguin:playSound(sound, opt)
  local sx, sy = self:getScreenLocation(self.engine.vw, self.engine.vh)
  AudioSource.playSound(self, sound, self.x - sx + self.engine.vw // 2, self.y - sy + self.engine.vh // 2, opt)
end

function Penguin:updateVolumeStereo()
  local sx, sy = self:getScreenLocation(self.engine.vw, self.engine.vh)
  AudioSource.updateVolumeStereo(self, self.x - sx + self.engine.vw // 2, self.y - sy + self.engine.vh // 2)
end

return Penguin
