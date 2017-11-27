-- include antarctica things
local ant = require 'antarctica'

local Tilemap = require 'tilemap'
local Image = require 'image'
local Object = require 'object'
local Engine = require 'engine'

-- the viewport
local vx, vy, vw, vh
vx = -200
vy = -150
vw = 400
vh = 300

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
    x = 0,
    y = 0,
    layer = 0,
    tx = 10,
    ty = 0,
    tw = 16,
    th = 32,
    animation_count = 1,
    animation_period = 1
}


-- These will store penguin's walking velocity.
penguin.wx = 0
penguin.wy = 0
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


-- Stop the penguin if it reaches a wall
function penguin:checkwallbump()
    if penguin.x <= 0 and penguin.wx < 0 then
        penguin.wx = 0
    end

    if penguin.y <= 0 and penguin.wy < 0 then
        penguin.wy = 0
    end

    local mapx, mapy = screentomap(penguin.x, penguin.y)
    if (map:get_flags(0, mapx, mapy) & ant.tilemap.bumpeastflag) ~= 0 then
        if penguin.wx < 0 then penguin.wx = 0 end
    end
    if (map:get_flags(0, mapx + 1, mapy) & ant.tilemap.bumpwestflag) ~= 0 then
        if penguin.wx > 0 then penguin.wx = 0 end
    end
    if (map:get_flags(0, mapx, mapy) & ant.tilemap.bumpsouthflag) ~= 0 then
        if penguin.wy < 0 then penguin.wy = 0 end
    end
    if (map:get_flags(0, mapx, mapy + 1) & ant.tilemap.bumpnorthflag) ~= 0 then
        if penguin.wy > 0 then penguin.wy = 0 end
    end
end


map:addObject(penguin)


-- Add NPCs
local dummylocations = {
    {x = 100, y = 100},
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



-- Keyboard handling callbacks
onkeydown = setmetatable({
        D = function() 
            penguin:turn('east')
            penguin.wx = penguin.stepsize 
        end,
        W = function() 
            penguin:turn('north')
            penguin.wy = -penguin.stepsize 
        end,
        A = function() 
            penguin:turn('west')
            penguin.wx = -penguin.stepsize 
        end,
        S = function() 
            penguin:turn('south')
            penguin.wy = penguin.stepsize 
        end,
        Escape = function() print('quitting...') engine:stop() end
    },
    {
        __index = function() return function() print('unhandled key') end end
    }
)

onkeyup = setmetatable({
        D = function() penguin.wx = 0 penguin:turn(penguin.direction) end,
        W = function() penguin.wy = 0 penguin:turn(penguin.direction) end,
        A = function() penguin.wx = 0 penguin:turn(penguin.direction) end,
        S = function() penguin.wy = 0 penguin:turn(penguin.direction) end,
    },
    {
        __index = function() return function() end end
    }
)


local min = function(a, b)
    if a > b then return a else return b end
end



engine:run{
    redraw = function(time, elapsed, counter)
        local actual_vx = min(0, vx)
        local actual_vy = min(0, vy)

        -- Redraw
        map:draw_layer(image, 0, actual_vx, actual_vy, vw, vh)
        map:draw_layer_objects(0, actual_vx, actual_vy, vw, vh)

        -- Update position
        penguin:checkwallbump()
        penguin:move(penguin.wx, penguin.wy)
        vx = vx + penguin.wx
        vy = vy + penguin.wy

        -- Update sprite
        if penguin.wx ~= 0 or penguin.wy ~= 0 then
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

