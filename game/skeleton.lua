-- Skeleton class for antarctica game -- Jan 21 2018, Ian
--

local Class = require "class"
local Object = require "object"

local Image = require "image"
local Sound = require "sound"

local Skeleton = Class.deriving(Object)

-- Load image, sound
local skeletonImage = Image{file = "res/skeleton-16x48.png"}
local skeletonSound = Sound{file = "res/skeleton-sound.wav"}

function Skeleton:init(options)
  -- TODO set up sprite coords
  --

  -- super init
  Object.init(self, options)

  -- set up other things 
end

function Skeleton:onupdate()
  -- if we're chasing someone, update velocity to follow greedily
  if type(self.target) == 'table' and self.target.class == 'player' then
    -- TODO follow
  end
end
