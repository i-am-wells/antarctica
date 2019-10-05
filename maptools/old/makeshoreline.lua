local ant = require "antarctica"

local p = function(x,y) 
    return setmetatable({x=x, y=y}, {
        __eq = function(a, b) 
            return (a.x == b.x) and (a.y == b.y)
        end,
        __add = function(a, b)
            return {x=(a.x + b.x), y=(a.y + b.y)}
        end,
        __sub = function(a, b)
            return {x=(a.x - b.x), y=(a.y - b.y)}
        end
    })
end


local b = function(x, y, dir)
    return {x=x, y=y, dir=dir}
end

local defaultShoreTilesOffset = p(3,8)
local defaultLegend = {
    e = defaultShoreTilesOffset + p(2,1),
    ne = defaultShoreTilesOffset + p(2,0),
    n = defaultShoreTilesOffset + p(1,0),
    nw = defaultShoreTilesOffset + p(0,0),
    w = defaultShoreTilesOffset + p(0,1),
    sw = defaultShoreTilesOffset + p(0,2),
    s = defaultShoreTilesOffset + p(1,2),
    se = defaultShoreTilesOffset + p(2,2),
    water = defaultShoreTilesOffset + p(1,1),
    land = p(0,0)
}

local defaultLegend2 = {
    nw0 = defaultShoreTilesOffset + p(1,0),
    ne0 = defaultShoreTilesOffset + p(2,0),
    n = defaultShoreTilesOffset + p(3,0),
    sw0 = defaultShoreTilesOffset + p(0,1),
    w = defaultShoreTilesOffset + p(1,1),
    nw1 = defaultShoreTilesOffset + p(3,1),
    se0 = defaultShoreTilesOffset + p(0,2),
    e = defaultShoreTilesOffset + p(2,2),
    ne1 = defaultShoreTilesOffset + p(3,2),
    s = defaultShoreTilesOffset + p(0,3),
    sw1 = defaultShoreTilesOffset + p(1,3),
    se1 = defaultShoreTilesOffset + p(2,3),
    cross0 = defaultShoreTilesOffset + p(2,1),
    cross1 = defaultShoreTilesOffset + p(1,2),
    water = p(1,9),
    land = p(0,0),
    upperlayer = {}
}

local terrainTilesOffset = defaultShoreTilesOffset + p(4, 0)
local terrainLegend = { 
    nw0 = terrainTilesOffset + p(1,0),
    ne0 = terrainTilesOffset + p(2,0),
    n = terrainTilesOffset + p(3,0),
    sw0 = terrainTilesOffset + p(0,1),
    w = terrainTilesOffset + p(1,1),
    nw1 = terrainTilesOffset + p(3,1),
    se0 = terrainTilesOffset + p(0,2),
    e = terrainTilesOffset + p(2,2),
    ne1 = terrainTilesOffset + p(3,2),
    s = terrainTilesOffset + p(0,3),
    sw1 = terrainTilesOffset + p(1,3),
    se1 = terrainTilesOffset + p(2,3),
    cross0 = terrainTilesOffset + p(2,1),
    cross1 = terrainTilesOffset + p(1,2),
    water = p(14,4),
    land = p(0,0),
    upperlayer = {}
    --[[
    upperlayer = {
        sw1 = true,
        se1 = true,
        n = true
    }--]]
}


local waterBoundFlags = {
    land = {},
    nw0 = {'se', 'nw'},
    ne0 = {'sw', 'ne'},
    n = {'n', 's'},
    sw0 = {'sw', 'ne'},
    w = {'e', 'w'},
    cross0 = {'ne', 'sw'},
    nw1 = {'nw', 'se'},
    se0 = {'nw', 'se'},
    cross1 = {'nw', 'se'},
    e = {'e', 'w'},
    ne1 = {'ne', 'sw'},
    s = {'n', 's'},
    sw1 = {'sw', 'ne'},
    se1 = {'se', 'nw'},
    water = {}
}

local terrainBoundFlags = {
    land = {},
    nw0 = {'nw'},
    ne0 = {'ne'},
    n = {'n', 's'},
    sw0 = {},
    w = {'e', 'w'},
    cross0 = {'ne'},
    nw1 = {'se'},
    se0 = {},
    cross1 = {'nw'},
    e = {'e', 'w'},
    ne1 = {'sw'},
    s = {b(0, -1, 's'), b(0, 1, 'n')},
    sw1 = {'w', 'ne'},
    se1 = {'w', 'nw'},
    water = {}
}

local patterns = {
    [0] = 'land',
    [1] = 'nw0',
    [2] = 'ne0',
    [3] = 'n',
    [4] = 'sw0', 
    [5] = 'w',
    [6] = 'cross0',
    [7] = 'nw1',
    [8] = 'se0',
    [9] = 'cross1',
    [10] = 'e',
    [11] = 'ne1',
    [12] = 's',
    [13] = 'sw1',
    [14] = 'se1',
    [15] = 'water'
}

local n = ant.tilemap.bumpnorthflag
local s = ant.tilemap.bumpsouthflag
local e = ant.tilemap.bumpeastflag
local w = ant.tilemap.bumpwestflag

local flagForTile = {
    [terrainTilesOffset.y + 0] = {
        [terrainTilesOffset.x + 0] = 0,
        [terrainTilesOffset.x + 1] = w | n,
        [terrainTilesOffset.x + 2] = e | n,
        [terrainTilesOffset.x + 3] = s | n
    },
    [terrainTilesOffset.y + 1] = {
        [terrainTilesOffset.x + 0] = 0,
        [terrainTilesOffset.x + 1] = e | w,
        [terrainTilesOffset.x + 2] = e,
        [terrainTilesOffset.x + 3] = s | e
    },
    [terrainTilesOffset.y + 2] = {
        [terrainTilesOffset.x + 0] = 0,
        [terrainTilesOffset.x + 1] = w,
        [terrainTilesOffset.x + 2] = e | w,
        [terrainTilesOffset.x + 3] = s | w,
    },
    [terrainTilesOffset.y + 3] = {
        [terrainTilesOffset.x + 0] = n,
        [terrainTilesOffset.x + 1] = n | s | e | w,
        [terrainTilesOffset.x + 2] = n | s | e | w,
        [terrainTilesOffset.x + 3] = 0
    },
    s = {
        [terrainTilesOffset.y + 1] = {
            [terrainTilesOffset.x + 0] = true,
            [terrainTilesOffset.x + 2] = true
        },
        [terrainTilesOffset.y + 2] = {
            [terrainTilesOffset.x + 0] = true,
            [terrainTilesOffset.x + 1] = true
        },
        [terrainTilesOffset.y + 3] = {
            [terrainTilesOffset.x + 0] = true,
            [terrainTilesOffset.x + 1] = true,
            [terrainTilesOffset.x + 2] = true
        }
    }
}


local checkTile = function(legend, key, tx, ty)
    return p(tx, ty) == legend[key]
end

local forEachTile = function(map, layer, fn)
    for y = 0, (map.h - 1) do
        for x = 0, (map.w - 1) do
            local tx, ty = map:getTile(layer, x, y)
            local flags = map:getFlags(layer, x, y)
            fn(x, y, tx, ty, flags)
        end
    end
end


return {
    convert = function(tilemap, layer, legend, boundRect)
        legend = legend or defaultLegend2

        boundRect = boundRect or {x=0, y=0, w=tilemap.w, h=tilemap.h}

        -- Row by row, convert tiles 
        for y = boundRect.y, (boundRect.y + boundRect.h - 1) do
            for x = boundRect.x, (boundRect.x + boundRect.w - 1) do
                
                local skip = false

                -- Find which tile to place
                local patternKey, place = 0, 8
                for _, k in ipairs{p(0,0), p(1,0), p(0,1), p(1,1)} do
                    -- Get the tile, or "water" if we're off the map
                    local tx, ty = tilemap:getTile(layer, k.x + x, k.y + y)

                    if not checkTile(legend, 'water', tx, ty) and not checkTile(legend, 'land', tx, ty) then
                        skip = true
                        break
                    end
                    
                    if (not tx) or (not ty) then
                        tx, ty = legend.water.x, legend.water.y
                    end

                    if checkTile(legend, 'water', tx, ty) or (not checkTile(legend, 'land', tx, ty)) then
                        patternKey = patternKey + place
                    end
                    place = place / 2
                end

                if patternKey ~= 15 and not skip then
                    local outTile = legend[patterns[patternKey]]

                    if legend.upperlayer[patterns[patternKey]] then
                        --tilemap:setTile(layer, x, y, legend.land.x, legend.land.y)
                        tilemap:setTile(layer+1, x, y, outTile.x, outTile.y)
                    else
                        -- Set tile
                        tilemap:setTile(layer, x, y, outTile.x, outTile.y)
                    end
                end

            end
        end

    end,


    autobump = function(map, layer, flagForTile)
        forEachTile(map, layer, function(x, y, tx, ty, flags)
            map:overwriteFlags(layer, x, y, 0)
        end)

        forEachTile(map, layer, function(x, y, tx, ty, flags)
            local flag = flagForTile[ty][tx]
            map:setFlags(layer, x, y, flag)

            if flagForTile.s[ty] and flagForTile.sy[ty][tx] then
                map:setFlags(layer, x, y-1, s)
            end
        end)
    end,

    terrainLegend = terrainLegend,
    shorelineLegend = defaultLegend
}

