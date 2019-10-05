
local Tilemap = require 'tilemap'

local script = arg[2]
local infile = arg[3]
local outfile = arg[4]


local map, err = Tilemap{file=infile}
if not map then
    error(err)
end

for y = 0, (map.h - 1) do
    for x = 0, (map.w - 1) do
        local tx, ty = map:getTile(1, x, y)
        if (tx ~= 16) or (ty ~= 0) then

            -- make layer 1 transparent
            map:setTile(1, x, y, 16, 0)
            --map:overwriteFlags(1, x, y, 0)

            -- set same tile in layer 0
            map:setTile(0, x, y, tx, ty)
            --map:setFlags(0, x, y, flags)
        end
    end
end

map:write(outfile)
