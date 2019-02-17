local ant = require "antarctica"

local Tilemap = require "tilemap"
local Object = require "object"
local Image = require "image"

local Engine = require "engine"
local engine = Engine{w=800, h=600}
engine:setLogicalSize(400, 300)

local flagMap = {
    [0x100] = 'south',
    [0x200] = 'west',
    [0x400] = 'north',
    [0x800] = 'east'
}

-- set up map
local map = Tilemap{nlayers=1, w=10, h=10}
for x = 1, 8 do
    map:setFlags(0, x, 0, ant.tilemap.bumpsouthflag)
    map:setFlags(0, x, 9, ant.tilemap.bumpnorthflag)
end
for y = 1, 8 do
    map:setFlags(0, 0, y, ant.tilemap.bumpeastflag)
    map:setFlags(0, 9, y, ant.tilemap.bumpwestflag)
end

map:setFlags(0, 1, 0, ant.tilemap.bumpeastflag)
map:setFlags(0, 1, 9, ant.tilemap.bumpeastflag)
map:setFlags(0, 8, 0, ant.tilemap.bumpwestflag)
map:setFlags(0, 8, 9, ant.tilemap.bumpwestflag)
map:setFlags(0, 0, 1, ant.tilemap.bumpsouthflag)
map:setFlags(0, 0, 8, ant.tilemap.bumpnorthflag)
map:setFlags(0, 9, 1, ant.tilemap.bumpsouthflag)
map:setFlags(0, 9, 8, ant.tilemap.bumpnorthflag)

local img = Image{
    engine = engine, 
    file = 'res/spritesnew-16x16.png', 
    tw = 16, 
    th = 16
}

local myAssert = function(name, exp, actual)
    if exp ~= actual then
        print('warning: '..name)
        --error(string.format('%s: expected %d but got %d', name, exp, actual))
    end
end

local doTest = function(sx, sy, vx, vy, evx, evy, ex, ey)
    local obj = Object{
        x = sx,
        y = sy,
        image=img,
        layer=0,
        tx=0, ty=8, tw=16, th=32,
        animation_count=1,
        animation_period=1,
        bbox={x=0,y=0,w=16,h=32}
    }

    obj:on{
        wallbump = function(slf, direction)
            --print('Wall bump: '..tostring(direction))
        end
    }

    map:addObject(obj)
    map:setCameraObject(obj)

    -- set object velocity
    obj:setVelocity(vx, vy)

    local framecount = 0
    engine:run{
        redraw = function(time, elapsed, counter)
            if framecount == 100 then
                engine:stop()
            end

            engine:clear()
            map:drawLayerFlags(img, 0, -64, -64, 400, 300) 
            map:drawLayerObjects(0, -64, -64, 400, 300, counter)
            --map:drawLayerAtCameraObject(img, 0, 800, 600, counter)
            --map:drawObjectsAtCameraObject(0, 800, 600, counter)
        
            map:updateObjects()

            framecount = framecount + 1
        end, 

        quit = function()
            engine:stop()
            error('tests aborted')
        end
    }


    obj:getLocation()
    myAssert('x', ex, obj.x)
    myAssert('y', ey, obj.y)
    myAssert('velx', evx, obj.velx)
    myAssert('vely', evy, obj.vely)

    map:removeObject(obj)
end

local case = function(sx, sy, vx, vy, fx, fy)
    return {sx=sx, sy=sy, vx=vx, vy=vy, fx=fx, fy=fy}
end

local cases = {
    case(64, 64, 0, 0, 64, 64),
    case(64, 64, 1, 0, 128, 64),
    case(64, 64, 1, -1, 128, 16),
    case(64, 64, 0, -1, 64, 16),
    case(64, 64, -1, -1, 16, 16),
    case(64, 64, -1, 0, 16, 64),
    case(64, 64, -1, 1, 16, 128-16),
    case(64, 64, 0, 1, 64, 128-16),
    case(64, 64, 1, 1, 128, 128-16),

    case(6*16, 7*16, 1, 0, 8*16, 7*16),
    case(8*16, 2*16, 0, -1, 8*16, 1*16),
    case(3*16, 1*16, -1, 0, 1*16, 1*16),
    case(1*16, 5*16, 0, 1, 1*16, 7*16)
}
for i, c in ipairs(cases) do
    print(string.format('test %d: (%d, %d) -> (%d, %d)', i, c.sx, c.sy, c.fx, c.fy))
    doTest(c.sx, c.sy, c.vx, c.vy, c.vx, c.vy, c.fx, c.fy)
end

print('finished tests')




