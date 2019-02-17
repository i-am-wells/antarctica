-- TODO consider removing

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

local topo = {
    defaultLegend = {
        blank = p(0,0),
            
    },

    forEachInLayer = function(tilemap, layer, fn)
        for y = 0, (tilemap.h - 1) do
            for x = 0, (tilemap.w - 1) do
                -- call
                local tx, ty = tilemap:getTile(layer, x, y)
                fn(layer, p(x, y), p(tx, ty))
            end
        end
    end
}

function topo.convert(tilemap, legend)
    local layer = 0
    legend = legend or topo.defaultLegend

    -- First, remove "jaggy" tiles
    topo.forEachInLayer(tilemap, layer, function(l, point, tile)
        if tile ~= legend.blank then
            -- look at neighbors, change if double
            local grid = {{false,false,false},{false,false,false},{false,false,false}}
            for _, n in ipairs{p(1,0), p(0,-1), p(-1,0), p(0,1)} do
                local neighbor = point + n
                local tx, ty = tilemap:getTile(layer, neighbor.x, neighbor.y)
                if p(tx, ty) ~= legend.blank then
                    grid[n.x+1][n.y+1] = true
                end
            end

            -- remove
            if (grid[1][0] and grid[0][1]) or (grid[1][0] and grid[2][1]) or (grid[2][1] and grid[1][2]) or (grid[1][2] and grid[0][1]) then
                tilemap:setTile(layer, point.x, point.y, legend.blank.x, legend.blank.y)
            end
        end
    end)


    -- Find direction markers; follow each
    topo.forEachInLayer(tilemap, layer, function(l, point, tile)
        if topo.isDirectional(tile, legend) then
            topo.convertLine(point, 
        end
    end)

end

return topo

