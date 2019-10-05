local math = require 'math'

local forEachTile = require 'maptools.forEachTile'


local groundTx, groundTy = 0, 0

local altTx0, altTy0 = 1, 1
local altTx1, altTy1 = 2, 1

-- Randomly changes some plain ground tiles to other ground tiles
forEachTile(arg[2], arg[3], 0, function(map, x, y, tx, ty, flags)
    
    if tx == groundTx and ty == groundTy then
        local roll = math.random()

        if roll < 0.0625 then
            map:setTile(0, x, y, altTx0, altTy0)
        elseif roll < 0.125 then
            map:setTile(0, x, y, altTx1, altTy1)
        end
    end
end)

