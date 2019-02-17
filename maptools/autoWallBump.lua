
local ant = require 'antarctica'
local forEachTile = require 'maptools.forEachTile'

local n = ant.tilemap.bumpnorthflag
local s = ant.tilemap.bumpsouthflag
local e = ant.tilemap.bumpeastflag
local w = ant.tilemap.bumpwestflag

local ns =  "_______"
local nss = "________"

local flagForTile = {
    [0] = {
        [1] = n | s | e | w,
        [3] = n | w,
        [4] = n | e,
        [5] = n,
        [6] = n | e,
        [9] = n | w,
        [10] = n,
        [13] = n | w,
    },
    [1] = {
        [3] = s | w,
        [4] = s | e,
        [5] = w,
        [7] = n | e,
        [8] = n | w, 
        [10] = e,
        [12] = n | w,
        [13] = s | e,
    },
    [2] = {
        [0] = n | w,
        [1] = n,
        [2] = n | e,
        [5] = w,
        [7] = e,
        [8] = w,
        [10] = s | e,
        [11] = n | w | s,
    },
    [3] = {
        [0] = w,
        [1] = n | s | e | w,
        [2] = e,
        [5] = s | w,
        [6] = s,
        [7] = s,
        [8] = s,
        [9] = s | e,
    },
    [4] = {
        [0] = s | w,
        [1] = s,
        [2] = s | e,
        [5] = n,
        [6] = n | e,
        [9] = n | w,
        [10] = n,
        [12] = n | w,
        [13] = n | s | e,
        [19] = n | w,
        [20] = n | e,
        [21] = n | s,

    },
    [5] = {
        [5] = s | w,
        [6] = e,
        [9] = w,
        [10] = s | e,
        [12] = s | e | w,
        [18] = ns,
        [19] = e | w,
        [20] = n | e,
        [21] = s | e
    },
    [6] = {
        [6] = s | w,
        [9] = s | e,
        [18] = ns,
        [19] = n | w,
        [20] = e | w,
        [21] = s | w,

    },
    [7] = {
        [13] = nss,
        [14] = n | s | e | w,
        [18] = nss,
        [19] = n | e,
        [20] = n | w,

    },
    [8] = {
        [6] = n | s,
        [8] = n | w,
        [9] = n | e,
        [10] = n | s,
        [11] = n | e | s,
        [12] = n | w | s,
        [15] = n | e | w,
        [19] = n | w,
        [20] = n | e,
        [21] = n,

    },
    [9] = {
        [4] = e | w,
        [6] = n | w,
        [7] = ns,
        [8] = e | w,
        [9] = e,
        [10] = s | e,
        [11] = s | w,
        [12] = s,
        [15] = s | e | w,
        [18] = ns,
        [19] = w,
        [20] = e,
        [24] = s,

    },
    [10] = {
        [5] = e | w,
        [6] = n | e,
        [7] = ns,
        [8] = w,
        [9] = e | w,
        [10] = s | w,
        [18] = ns,
        [19] = w,
        [20] = e,
    },
    [11] = {
        [3] = n | s,
        [4] = s | w,
        [5] = s | e,
        [7] = nss,
        [8] = n | e | w,
        [9] = n | e | w,
        [13] = nss,
        [14] = n | e | w,
        [18] = nss,
        [19] = w,
        [20] = e,

    },
    [12] = {
        [8] = n | w,
        [9] = n | e,
        [10] = n | s,
        [14] = s | e | w,

    },
    [13] = {
        [7] = ns,
        [8] = e | w,
        [9] = e,
        [10] = s | e,

    },
    [14] = {
        [7] = ns,
        [8] = w,
        [9] = e | w,
        [10] = s | w,
        [24] = s,
        [25] = s,
        [26] = s,

    },
    [15] = {
        [7] = nss,
        [8] = n | e | w,
        [9] = n | e | w,
        [23] = s | e,
        [27] = s | w,

    },
    [16] = {
        [22] = s | e,
        [28] = s | w,
    },
    [25] = {
        [13] = n | w,
        [14] = n,
        [15] = n,
        [16] = n,
        [17] = n | e,

    },
    [26] = {
        [12] = n | w,
        [18] = n | e,

    },
    [27] = {
        [12] = w,
        [18] = e,
    },
    [28] = {
        [12] = w,
        [18] = e,
    },
    [29] = {
        [12] = w,
        [18] = e,
    },
    [30] = {
        [12] = s | w,
        [13] = s,
        [14] = e,
        [15] = s,
        [16] = w,
        [17] = s,
        [18] = s | e,
        [19] = n | e | w,
    },
    [31] = {
        [14] = s | e | w,
        [16] = s | e | w,
        [19] = s | e | w
    }
}


local doBump = function(map, x, y, tx, ty, flags)

    if flagForTile[ty] and flagForTile[ty][tx] then
        local f = flagForTile[ty][tx]
        if f == ns then
            map:setFlags(1, x, y-1, s)
        elseif f == nss then
            map:setFlags(1, x, y-1, s)
            map:setFlags(1, x, y, n)
        else
            map:setFlags(1, x, y, f)
        end
    end
end


-- For each tile, look up flags and set (layer 1)
forEachTile(arg[2], arg[3], 0, doBump)
forEachTile(arg[3], arg[3], 1, doBump)

