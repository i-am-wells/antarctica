local ant = require 'antarctica' 

local p = function(x, y) return {x=x, y=y} end
local layer1tiles = {
    [2]={[0]=true},
    [3]={[0]=true},
    [5]={[0]=true},
    [0]={[2]=true, [3]=true},
    [7]={[2]=true, [3]=true}
}

local patchMap = function(map, patch, x, y)
    local layer = 0 -- TODO change

    local px, py
    for py = 0, (patch.h - 1) do
        for px = 0, (patch.w - 1) do
            local mx, my = x+px, y+py
            if (mx < map.w) and (my < map.h) then
                local patchX, patchY = patch.x+px, patch.y+py
                if layer1tiles[patchX] and layer1tiles[patchX][patchY] then
                    map:setTile(layer, mx, my, 0, 0)
                    map:setTile(layer+1, mx, my, patchX, patchY)
                else
                    map:setTile(layer, mx, my, patchX, patchY)
                end
            end
        end
    end
end

local rect = function(x, y, w, h) return {x=x, y=y, w=w, h=h} end

local directions = {
    nw = {x=-1, y=-1},
    n = {x=0, y=-1},
    ne = {x=1, y=-1},
    w = {x=-1, y=0},
    e = {x=1, y=0},
    sw = {x=-1, y=1},
    s = {x=0, y=1},
    se = {x=1, y=1}
}

local patches = {
    a1 = rect(1,0,1,1),
    a2 = rect(2,0,1,1),
    a3 = rect(3,0,1,1),
    a5 = rect(5,0,1,1),
    b0 = rect(0,1,1,1),
    b2 = rect(2,1,1,3),
    b3 = rect(3,1,1,3),
    b4 = rect(4,1,1,3),
    b5 = rect(5,1,1,3),
    c0 = rect(0,2,1,2),
    c7 = rect(7,2,1,2),
    d7 = rect(7,3,1,1),
    e0 = rect(0,4,1,3),
    e1 = rect(1,4,1,4),
    e2 = rect(2,4,1,1),
    e3 = rect(3,4,1,1),
    e5 = rect(5,4,1,1),
    e6 = rect(6,4,1,4),
    e7 = rect(7,4,1,3),
    f2 = rect(2,5,1,3),
    f5 = rect(5,5,1,3),
    g3 = rect(3,6,1,2)
}


local bumpFlags = {
    e = ant.tilemap.bumpeastflag,
    ne = ant.tilemap.bumpnortheastflag,
    n = ant.tilemap.bumpnorthflag,
    nw = ant.tilemap.bumpnorthwestflag,
    w = ant.tilemap.bumpwestflag,
    sw = ant.tilemap.bumpsouthwestflag,
    s = ant.tilemap.bumpsouthflag,
    se = ant.tilemap.bumpsoutheastflag
}
local b = function(x, y, flags)
    local flagT = {}
    for i, flag in ipairs(flags) do
        flagT[i] = bumpFlags[flag]
    end
    return {x=x, y=y, flags=flagT}
end
local tileBumpFlags = {
    a1 = {b(0,0,{'e','w'})},
    a2 = {b(0,0,{'nw','se'}), b(0,1,{'nw'})},
    a3 = {b(0,-1,{'s'}), b(0,1,{'n'})},
    a5 = {b(0,0,{'ne','sw'}), b(0,1,{'ne'})},
    b0 = {b(0,0,{'e','w'})},
    b2 = {b(0,0,{'nw'}), b(0,1,{'w'}), b(0,2,{'w'})},
    b3 = {b(0,0,{'n'}), b(0,2,{'se'})},
    b4 = {b(0,0,{'n'}), b(0,2,{'sw'})},
    b5 = {b(0,0,{'ne'}), b(0,1,{'e'}), b(0,2,{'e'})},
    c0 = {b(0,0,{'e'}), b(1,0,{'w'}), b(0,1,{'nw', 'e'})},
    c7 = {b(0,0,{'w'}), b(-1,0,{'e'}), b(0,1,{'w', 'ne'})},
    e0 = {b(0,0,{'w'}), b(0,1,{'w'}), b(0,2,{'sw'})},
    e1 = {b(0,0,{'ne'}), b(0,3,{'sw'})},
    e2 = {b(0,0,{'sw', 'e'})},
    e5 = {b(0,0,{'w', 'se'})},
    e6 = {b(0,0,{'nw'}), b(0,3,{'se'})},
    e7 = {b(0,0,{'e'}), b(0,1,{'e'}), b(0,2,{'se'})},
    f2 = {b(0,0,{'ne'}), b(0,2,{'s'})},
    f5 = {b(0,0,{'nw'}), b(0,2,{'s'})},
    g3 = {b(0,0,{'n'}), b(0,1,{'s'})}
}


local linePatches = {
    e = 'g3',
    ne = 'e6',
    n = 'a1',
    nw = 'a5',
    w = 'a3',
    sw = 'a2',
    s = 'b0',
    se = 'e1'
}


local t = function(sx, sy, fp, dx, dy) return {sx=sx, sy=sy, fp=fp, dx=dx, dy=dy} end
local transitions = {
    e = {
        ne = t(1,-1,'f5',2,-2),
        se = t(-1,0,'b4',0,0)
    },
    ne = {
        n = t(0,1,'e7',0,0),
        e = t(1,0,'b3',2,0)
    },
    n = {
        nw = t(0,0,'c7',-1,-1),
        ne = t(0,0,'b2',1,-1)
    },
    nw = {
        w = t(0,0,'a5',-1,0),
        n = t(0,0,'e2',0,-1)
    },
    w = {
        sw = t(0,0,'a2',-1,1),
        nw = t(0,0,'a3',-1,-1)
    },
    sw = {
        s = t(0,0,'c0',0,2),
        w = t(0,0,'a3',-1,0)
    },
    s = {
        se = t(0,1,'e0',1,1),
        sw = t(0,0,'e5',-1,1)
    },
    se = {
        e = t(-1,-1,'f2',0,0),
        s = t(0,0,'b5',0,3)
    }
}


local setBumpFlags = function(map, bf, x, y)
    for _, v in ipairs(bf) do
        local mask = 0
        for __, flag in ipairs(v.flags) do
            mask = mask | flag
        end
        map:overwriteFlags(0, x+v.x, y+v.y, mask)
    end
end


local drawTerrain = function(map, lastDir, dir, sx, sy, dx, dy, setFlags)
    local transition = transitions[lastDir][dir]

    if lastDir == dir then
        transition = t(0,0,linePatches[dir],0,0)
    end
    for k, v in pairs(transition) do print(k,v) end

    -- Patch transition
    patchMap(map, patches[transition.fp], sx+transition.sx, sy+transition.sy)
    if setFlags then
        setBumpFlags(map, tileBumpFlags[transition.fp], sx+transition.sx, sy+transition.sy)
    end

    local cx, cy = sx+transition.dx, sy+transition.dy
    
    local v, patch = directions[dir], patches[linePatches[dir]]
    print(dir, linePatches[dir])
    
    while (cx ~= dx) or (cy ~= dy) do
        patchMap(map, patch, cx, cy)
        if setFlags then
            setBumpFlags(map, tileBumpFlags[linePatches[dir]], cx, cy)
        end

        cx = cx + v.x
        cy = cy + v.y
    end
    patchMap(map, patch, dx, dy)
    if setFlags then
        setBumpFlags(map, tileBumpFlags[linePatches[dir]], dx, dy)
    end
end

-- to find all valid next drawing directions, use keys from transitions tables above
local validNextDirections = function(prevDir)
    local t = transitions[prevDir]
    local ret = {prevDir}
    for k,v in pairs(t) do
        table.insert(ret, k)
    end
    return ret
end

return {
    drawTerrain = drawTerrain,
    validNextDirections = validNextDirections,

    getMoveDirection = function(sx, sy, dx, dy, dir)
        local diffX, diffY = dx - sx, dy - sy

        if diffX ~= 0 and diffY ~= 0 and math.abs(diffX) ~= math.abs(diffY) then
            return nil
        end

        if diffX ~= 0 then
            diffX = diffX // math.abs(diffX)
        end
        if diffY ~= 0 then
            diffY = diffY // math.abs(diffY)
        end

        for _, vdir in ipairs(validNextDirections(dir)) do
            local v = directions[vdir]
            if diffX == v.x and diffY == v.y then
                return vdir
            end
        end
        
        return nil
    end,

    directions = directions
}

