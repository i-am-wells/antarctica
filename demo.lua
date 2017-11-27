
local ant = require 'antarctica'

local Tilemap = require 'tilemap'
local Image = require 'image'
local Object = require 'object'
local Engine = require 'engine'


local vx, vy, vw, vh
vx = -200
vy = -150
vw = 400
vh = 300

local engine = Engine{ title = 'Demo', w = 800, h = 600, 
        windowflags = 0 }
engine:setlogicalsize(vw, vh)
engine:setcolor(255, 255, 255, 255)

local map = Tilemap{ file = 'test.map' }

local image = Image{ engine = engine, file = 'res/terrain.png', tw = 16, th = 16 }


local guy = Object{
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


guy.wx = 0
guy.wy = 0
guy.stepsize = 2

guy.walkinfo = {
    north = { tx = 11, ty = 0 },
    south = { tx = 10, ty = 0 },
    east = { tx = 12, ty = 0 },
    west = { tx = 13, ty = 0 }
}
guy.walkY = { 0, 1, 0, 2 }


function guy:turn(direction)
    guy.direction = direction
    local winfo = guy.walkinfo[direction]
    guy:setsprite(winfo.tx, winfo.ty)
end

function guy:setspriteY(count)
    local frame = (count // 4) % 4
    local winfo = guy.walkinfo[guy.direction]
    guy:setsprite(winfo.tx, winfo.ty + guy.walkY[frame+1])
end

-- convert between map and screen coordinates
local screentomap = function(x, y)
    local mapx = (x) // image.tw
    local mapy = (y) // image.th
    return mapx, mapy
end

function guy:checkwallbump()
    if guy.x <= 0 and guy.wx < 0 then
        guy.wx = 0
    end

    if guy.y <= 0 and guy.wy < 0 then
        guy.wy = 0
    end

    local mapx, mapy = screentomap(guy.x, guy.y)
    if (map:get_flags(0, mapx, mapy) & ant.tilemap.bumpeastflag) ~= 0 then
        if guy.wx < 0 then guy.wx = 0 end
    end
    if (map:get_flags(0, mapx + 1, mapy) & ant.tilemap.bumpwestflag) ~= 0 then
        if guy.wx > 0 then guy.wx = 0 end
    end
    if (map:get_flags(0, mapx, mapy) & ant.tilemap.bumpsouthflag) ~= 0 then
        if guy.wy < 0 then guy.wy = 0 end
    end
    if (map:get_flags(0, mapx, mapy + 1) & ant.tilemap.bumpnorthflag) ~= 0 then
        if guy.wy > 0 then guy.wy = 0 end
    end
end


map:addObject(guy)

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



onkeydown = setmetatable({
        D = function() 
            guy:turn('east')
            guy.wx = guy.stepsize 
        end,
        W = function() 
            guy:turn('north')
            guy.wy = -guy.stepsize 
        end,
        A = function() 
            guy:turn('west')
            guy.wx = -guy.stepsize 
        end,
        S = function() 
            guy:turn('south')
            guy.wy = guy.stepsize 
        end,
        Escape = function() print('quitting...') engine:stop() end
    },
    {
        __index = function() return function() print('unhandled key') end end
    }
)

onkeyup = setmetatable({
        D = function() guy.wx = 0 guy:turn(guy.direction) end,
        W = function() guy.wy = 0 guy:turn(guy.direction) end,
        A = function() guy.wx = 0 guy:turn(guy.direction) end,
        S = function() guy.wy = 0 guy:turn(guy.direction) end,
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
        guy:checkwallbump()
        guy:move(guy.wx, guy.wy)
        vx = vx + guy.wx
        vy = vy + guy.wy

        -- Update sprite
        if guy.wx ~= 0 or guy.wy ~= 0 then
            guy:setspriteY(counter)
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

