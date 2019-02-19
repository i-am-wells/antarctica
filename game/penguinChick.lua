local Class = require 'class'
local Penguin = require 'game.penguin'

local PenguinChick = Class(Penguin)

-- PenguinChick is just a Penguin with different sprites and bounding box.
PenguinChick.sprites = {
    stand = {
        north = {{tx=1, ty=8, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16}},
        south = {{tx=0, ty=8, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16}},
        east = {{tx=2, ty=8, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16}},
        west = {{tx=3, ty=8, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16}},
        timing = {div=1, mod=1, [0]=1} 
    },
    walk = {
        north = {
            {tx=1, ty=8, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
            {tx=1, ty=9, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
            {tx=1, ty=10, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
        },
        south = {
            {tx=0, ty=8, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
            {tx=0, ty=9, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
            {tx=0, ty=10, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
        },
        east = {
            {tx=2, ty=8, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
            {tx=2, ty=9, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
            {tx=2, ty=10, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
        },
        west = {
            {tx=3, ty=8, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
            {tx=3, ty=9, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
            {tx=3, ty=10, tw=16, th=32, bbox={x=0, y=0, w=14, h=14}, offX=0, offY=-16},
        },
        timing = {
            mod = 4,
            div = 4,
            [0] = 2,
            [1] = 1,
            [2] = 3,
            [3] = 1
        }
    }
}

return PenguinChick

