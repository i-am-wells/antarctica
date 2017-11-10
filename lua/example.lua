-- Example script

--local acc = require('accursed')

local Engine = require 'engine'
local Image = require 'image'

-- Create engine
local engine = Engine{title='Example'}

--local tiles = acc.Image{file='tiles16x16.png'}

local sprite = Image{engine=engine, file='res/sprite.jpg', tilew=16, tileh=16}

--local tilemap = acc.Tilemap{file='example.map', tiles=tiles}
-- TODO add objects


local spriteX, spriteY = 100, 100
local dx, dy = 0, 0


local printevent = function(name)
    return function(...)
        print(name)
        for _, v in ipairs{...} do
            print('\t' .. tostring(v))
        end
        print('')
    end
end


engine:on{
    redraw = function(tick, elapsed)
       
        --print(elapsed)
        sprite:drawwhole(spriteX, spriteY)

        spriteX = spriteX + dx
        spriteY = spriteY + dy

    end,

    keydown = printevent('keydown'),
    keyup = printevent('keyup'),
    mousebuttondown = printevent('mousebuttondown'),
    mousebuttonup = printevent('mousebuttonup')
}


engine:run()


