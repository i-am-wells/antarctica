-- include antarctica things
local ant = require 'antarctica'

local Tilemap = require 'tilemap'
local Image = require 'image'
local Object = require 'object'
local Engine = require 'engine'

-- our actor class
local Penguin = require 'penguin'



-- the view size
local vw = 400
local vh = 300

local keysdown = 0


-- Create a window. "setlogicalsize" lets us render everything normally but
-- will scale the canvas to match the window.
local engine = Engine{ title = 'Demo', w = vw * 2, h = vh * 2, 
        windowflags = ant.engine.fullscreen }
engine:setlogicalsize(vw, vh)
engine:setcolor(255, 255, 255, 255) -- white background

-- Load the map
local map = Tilemap{ file = 'test.map' }

-- Load the tiles and sprites
local image = Image{ engine = engine, file = 'res/terrain.png', tw = 16, th = 16 }

-- convert between map and pixel coordinates
local screentomap = function(x, y)
    local mapx = (x) // image.tw
    local mapy = (y) // image.th
    return mapx, mapy
end



-- Create the player object. It will use sprites from terrain.png.
local penguin = Penguin{
    image = image,
    x = 232,
    y = 364,
    layer = 0,
}


-- Set up the penguin
penguin:turn('south')
map:addObject(penguin)
map:setCameraObject(penguin)

local font = Image{engine = engine, file = 'res/text-6x12.png', tilew = 6, tileh = 12}
local descriptiontext = nil

-- Set up the interactive fish space (0, 24, 15)
map:setInteractCallback(0, 24, 15, function(obj)
    descriptiontext = "It's a fish."
    print('interact!')
end)


-- Add NPCs
local npclocations = {
    {x = 100, y = 400},
    {x = 100, y = 500},
    {x = 100, y = 100},
    {x = 200, y = 200}
}

for _, loc in ipairs(npclocations) do
    local npc = Penguin{
        image = image,
        x = loc.x,
        y = loc.y,
        layer = 0,
    }
    npc:turn('south')
    map:addObject(npc)
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
        Space = function()
            if descriptiontext then
                descriptiontext = nil
            end
            penguin:interact(map)
        end,
        Escape = function() print('quitting...') engine:stop() end
    },
    {
        __index = function(_, key) return function() print('unhandled key '..key) end end
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
        map:drawLayerAtCameraObject(image, layer, vw, vh, counter)
        map:drawObjectsAtCameraObject(layer, vw, vh)

        if descriptiontext then
            -- Draw box and show text
            engine:fillrect(100, 200, 200, 50)
            engine:setcolor(0, 0, 0, 255)
            engine:drawrect(100, 200, 200, 50)
            engine:drawrect(102, 202, 196, 46)
            engine:setcolor(255, 255, 255, 255)
            font:drawtext(descriptiontext, 104, 204, 192)
        end

        -- TODO run all callbacks set with setInterval or setTimeout
        --engine:runCallbacks()

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
            if key ~= 'Space' then
                descriptiontext = nil
            end
        end
    end,

    keyup = function(key)
        onkeyup[key]()
    end
}

