
local Tilemap = require 'tilemap'


return function(infile, outfile, layer, fn)

    local map, err = Tilemap{file=infile}
    if not map then
        error(err)
    end

    for y = 0, (map.h - 1) do
        for x = 0, (map.w - 1) do
            local tx, ty = map:getTile(layer, x, y)
            local flags = map:getFlags(layer, x, y)

            -- run per-tile
            fn(map, x, y, tx, ty, flags)
        end
    end

    map:write(outfile)
end

