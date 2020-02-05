local Class = require 'class'
local Item = require 'game.items.item'

local CarbideHeadlamp = Class(Item)

CarbideHeadlamp.name = 'carbide headlamp'
CarbideHeadlamp.tx = 0
CarbideHeadlamp.ty = 5 -- TODO ???

CarbideHeadlamp.isHeadgear = true

-- TODO lighting in cave when equipped and before fuel runs out
-- approach: every three seconds, decrease fuel level
--
-- if fuel > 0, on draw, don't use "dark" recolor
--
-- Cave darkness: don't draw beyond circle, also overlay


return CarbideHeadlamp
