
local forEachTile = require 'maptools.forEachTile'

local sT = {[8]={[10]=true}, [12]={[10]=true}}
local gT = {[0]={[0]=true}, [1]={[1]=true, [2]=true}, [8]={[7]=true, [10]=true}, [12]={[10]=true}}

local low = {{x=1, y=4}, {x=10,y=8}}
local mid = {{x=1, y=3}}
local hi = {{x=1,y=2}, {x=5,y=4}, {x=10, y=12}}

local makeInteresting = function(map, left, right)
    local x0, x1 = left.x, right.x
    if x0 == x1 then
        return
    end
    
    print(left.x, left.y, right.x, right.y)
    local content
    for yy = left.y, (left.y - 4), -1 do
        if yy == left.y then
            content = low
        elseif yy == (left.y - 4) then
            content = hi
        else
            content = mid
        end

        -- check if row is clear
        for xx = x0, x1 do
            local tx, ty = map:getTile(0, xx, yy)
            if (not gT[ty]) or (not gT[ty][tx]) then 
                content = hi
            end
        end

        -- shrink a little
        x0 = x0 + (math.random() * 3 // 1)
        x1 = x1 - (math.random() * 3 // 1)

        if x0 >= x1 then
            return
        end

        -- copy in tiles
        if content ~= low then
            map:setTile(0, x0, yy, 12, 8)
            map:setTile(0, x1, yy, 11, 8)
        end
        for xx = (x0 + 1), (x1 - 1) do
            local choice = content[1 + (math.random() * #content // 1)]
            map:setTile(0, xx, yy, choice.x, choice.y)
        end

        if content == hi then
            break
        end
    end
end


local left, right = nil, nil
forEachTile(arg[2], arg[3], 0, function(map, x, y, tx, ty, flags)

    -- identify straight lines of south-facing slopes and do something more
    -- interesting with them
    --


    if sT[ty] and sT[ty][tx] then
        if not left then
            left = {x=x, y=y}
        end
        right = {x=x, y=y}
    elseif left then

        print('ere')
        makeInteresting(map, left, right)

        left = nil
        right = nil
    end
end)

