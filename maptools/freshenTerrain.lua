local math = require 'math'

local forEachTile = require 'maptools.forEachTile'

-- 0: ground
-- 1: sw (concave)
-- 2: sw (convex)
-- 3: se (concave)
-- 4: se (convex)
--
-- 5: nw (convex)
-- 6: nw (concave)
-- 7: ne (convex)
-- 8: ne (concave)
--
local categories = {
    [0] = {
        [0] = 0
    },
    [1] = {
        [1] = 0
    },
    [2] = {
        [1] = 0
    },
    [7] = {
        [8] = 0,
        [9] = 8,
        [10] = 6,
        [11] = 9,
    },
    [8] = {
        [8] = 3,
        [9] = 10,
        [10] = 11,
        [11] = 7

    },
    [9] = {
        [8] = 1,
        [9] = 12,
        [10] = 13,
        [11] = 5
    },
    [10] = {
        [8] = 14,
        [9] = 4,
        [10] = 2,
        [11] = 15
    },
}

local patches = {
    slantSE = {x=5, y=0, w=3, h=4, prob=0.65},
    slantNE = {x=8, y=0, w=3, h=4, prob=0.65},
    slantShortSE = {x=5, y=4, w=2, h=3, prob=0.75},
    slantShortNE = {x=9, y=4, w=2, h=3, prob=0.75},

    slantNW = {x=11, y=0, w=3, h=4, prob=0.65},
    slantSW = {x=13, y=7, w=3, h=4, prob=0.65},
    slantShortNW = {x=12, y=4, w=2, h=3, prob=0.75},
    slantShortSW = {x=13, y=11, w=2, h=3, prob=0.75},
    
    ground = {x=1,y=1,w=1,h=1,prob=0.0625},
    n = {x=7,y=15,w=1,h=1,prob=0.5},
    e = {x=8,y=13,w=1,h=1,prob=0.5},
    c1 = {x=8,y=14,w=1,h=1,prob=0.5},
    c0 = {x=9,y=13,w=1,h=1,prob=0.5},
    w = {x=9,y=14,w=1,h=1, prob=0.5},
    s = {x=10,y=12,w=1,h=1,prob=0.5},
    ground2 = {x=10,y=15, w=1,h=1, prob=0.5}
}

local patterns = {
    slantSE = {
        {1, 0, 0},
        {2, 1, 0},
        {0, 2, 1},
        {0, 0, 2}
    },
    slantNE = {
        {0, 0, 3},
        {0, 3, 4},
        {3, 4, 0},
        {4, 0, 0}
    },
    slantShortSE = {
        {1, 0},
        {2, 1},
        {0, 2}
    },
    slantShortNE = {
        {0, 3},
        {3, 4},
        {4, 0}
    },
    slantNW = {
        {0, 0, 5},
        {0, 5, 6},
        {5, 6, 0},
        {6, 0, 0}
    },
    slantShortNW = {
        {0, 5},
        {5, 6},
        {6, 0}
    },
    slantSW = {
        {7, 0, 0},
        {8, 7, 0},
        {0, 8, 7},
        {0, 0, 8}
    },
    slantShortSW = {
        {7, 0},
        {8, 7},
        {0, 8}
    }
    --[[
    ground = {{0}},
    n = {{9}},
    e = {{10}},
    c1 = {{11}},
    c0 = {{12}},
    w = {{13}},
    s = {{14}},
    ground2 = {{15}}
    --]]

}

local checkPattern = function(map, x, y, pattern)

    for yy, row in ipairs(pattern) do
        for xx, category in ipairs(row) do 
            local mapTx, mapTy = map:getTile(0, x + xx - 1, y + yy - 1)

            if mapTx == nil or mapTy == nil then
                return false
            end

            local fail = true
            if (not categories[mapTx]) or (categories[mapTx][mapTy] ~= category) then
                return false
            end
        end
    end

    return true
end

local applyPatch = function(map, x, y, patch)
    for yy = 0, (patch.h - 1) do
        for xx = 0, (patch.w - 1) do
            map:setTile(0, x + xx, y + yy, patch.x + xx, patch.y + yy)
        end
    end
end

forEachTile(arg[2], arg[3], 0, function(map, x, y, tx, ty, flags)
    -- Check for match
    local didPatch = false
    for name, pattern in pairs(patterns) do
        
        if checkPattern(map, x, y, pattern) then
            local patch = patches[name]
            
            -- roll dice and copy in the pattern
            local roll = math.random()

            if roll < patch.prob then
                -- apply patch
                applyPatch(map, x, y, patch)
                didPatch = true
            end
        end
    end

    if not didPatch then
        local roll = math.random()
        if (tx >= 7) and (tx <= 10) and (ty >= 8) and (ty <= 11) then
            if roll < 0.5 then
                map:setTile(0, x, y, tx, ty+4)
            end
        elseif (tx == 0) and (ty == 0) then
            if roll < 0.0625 then
                map:setTile(0, x, y, 1, 1)
            elseif roll < 0.125 then
                map:setTile(0, x, y, 2, 1)
            end
        end
    end

end)

