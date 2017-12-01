-- include antarctica things
local ant = require 'antarctica'

local Tilemap = require 'tilemap'
local Image = require 'image'
local Object = require 'object'
local Engine = require 'engine'

local Penguin = require 'penguin'

-- TODO remove
-- the viewport
local vx, vy, vw, vh
vx = -200
vy = -150
vw = 400
vh = 300

local keysdown = 0


-- Create a window. "setlogicalsize" lets us render everything normally but
-- will scale the canvas to match the window.
local engine = Engine{ title = 'Demo', w = vw * 2, h = vh * 2, 
        windowflags = 0 }
engine:setlogicalsize(vw, vh)
engine:setcolor(255, 255, 255, 255) -- white background

-- Load the map
local map = Tilemap{ file = 'test.map' }

-- Load the tiles and sprites
local image = Image{ engine = engine, file = 'res/terrain.png', tw = 16, th = 16 }

-- Create the player object. It will use sprites from terrain.png.
local penguin = Object{
    image = image,
    x = 32,
    y = 64,
    layer = 0,
    tx = 10,
    ty = 0,
    tw = 16,
    th = 32,
    animation_count = 1,
    animation_period = 1
}


-- Penguin's walking velocity
penguin.stepsize = 2

-- Used for looking up which sprite to use for each direction the penguin
-- can face.
penguin.walkinfo = {
    north = { tx = 11, ty = 0 },
    south = { tx = 10, ty = 0 },
    east = { tx = 12, ty = 0 },
    west = { tx = 13, ty = 0 }
}
-- For the walking animation
penguin.walkY = { 0, 1, 0, 2 }


-- Turns the penguin to face north, south, east, or west
function penguin:turn(direction)
    penguin.direction = direction
    local winfo = penguin.walkinfo[direction]
    penguin:setsprite(winfo.tx, winfo.ty)
end

-- Update the penguin's sprite to create the walking animation
function penguin:setspriteY(count)
    local frame = (count // 4) % 4
    local winfo = penguin.walkinfo[penguin.direction]
    penguin:setsprite(winfo.tx, winfo.ty + penguin.walkY[frame+1])
end

-- convert between map and pixel coordinates
local screentomap = function(x, y)
    local mapx = (x) // image.tw
    local mapy = (y) // image.th
    return mapx, mapy
end

penguin:turn('south')
map:addObject(penguin)
map:setCameraObject(penguin)

-- Add NPCs
local dummylocations = {
    {x = 100, y = 400},
    {x = 100, y = 500},
    {x = 100, y = 100},
    {x = 200, y = 200}
}

for _, loc in ipairs(dummylocations) do
    local dummy = Object{
        image = image,
        x = loc.x,
        y = loc.y,
        layer = 0,
        tx = 10,
        ty = 0,
        tw = 16,
        th = 32,
        animation_count = 1,
        animation_period = 1
    }

    map:addObject(dummy)
end

function penguin:updateDirection()
    if penguin.direction == 'north' then
        if penguin.vely > 0 then
            penguin:turn('south')
        elseif penguin.vely == 0 then
            if penguin.velx > 0 then
                penguin:turn('east')
            elseif penguin.velx < 0 then
                penguin:turn('west')
            end
        end
    elseif penguin.direction == 'south' then
        if penguin.vely < 0 then
            penguin:turn('north')
        elseif penguin.vely == 0 then
            if penguin.velx > 0 then
                penguin:turn('east')
            elseif penguin.velx < 0 then
                penguin:turn('west')
            end
        end
    elseif penguin.direction == 'east' then
        if penguin.velx < 0 then
            penguin:turn('west')
        elseif penguin.velx == 0 then
            if penguin.vely > 0 then
                penguin:turn('south')
            elseif penguin.vely < 0 then
                penguin:turn('north')
            end
        end
    elseif penguin.direction == 'west' then
        if penguin.velx > 0 then
            penguin:turn('east')
        elseif penguin.velx == 0 then
            if penguin.vely > 0 then
                penguin:turn('south')
            elseif penguin.vely < 0 then
                penguin:turn('north')
            end
        end
    end
end

-- Keyboard handling callbacks
onkeydown = setmetatable({
        D = function() 
            penguin:setVelocity(penguin.stepsize, nil)
            penguin:updateDirection()
        end,
        W = function() 
            penguin:setVelocity(nil, -penguin.stepsize)
            penguin:updateDirection()
        end,
        A = function() 
            penguin:setVelocity(-penguin.stepsize, nil)
            penguin:updateDirection()
        end,
        S = function() 
            penguin:setVelocity(nil, penguin.stepsize)
            penguin:updateDirection()
        end,
        Escape = function() print('quitting...') engine:stop() end
    },
    {
        __index = function() return function() print('unhandled key') end end
    }
)


onkeyup = setmetatable({
        D = function() 
            penguin:setVelocity(0, nil)
            penguin:updateDirection()
        end,
        W = function() 
            penguin:setVelocity(nil, 0)
            penguin:updateDirection()
        end,
        A = function() 
            penguin:setVelocity(0, nil)
            penguin:updateDirection()
        end,
        S = function() 
            penguin:setVelocity(nil, 0)
            penguin:updateDirection()
        end,
    },
    {
        __index = function() return function() end end
    }
)



local layer = 0

-- Install handlers and run
engine:run{
    redraw = function(time, elapsed, counter)
        -- Redraw
        map:drawLayerAtCameraObject(image, layer, vw, vh)
        map:drawObjectsAtCameraObject(layer, vw, vh)

        -- Update object positions
        map:updateObjects()

        -- Update sprite
        if penguin.velx ~= 0 or penguin.vely ~= 0 then
            penguin:setspriteY(counter) 
        end
    end,

    keydown = function(key, mod, isrepeat)
        if isrepeat == 0 then
            onkeydown[key]()
        end
    end,

    keyup = function(key)
        onkeyup[key]()
    end
}

