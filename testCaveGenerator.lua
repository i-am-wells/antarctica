local math = require 'math'
local os = require 'os'

local package = require 'package'
package.path = package.path..';./lua/?.lua'
local ant = require 'antarctica'
ant.init()

local tilesetInfo = require 'maptools.cave.tilesetInfo'
local CaveGenerator = require 'maptools.CaveGenerator'
local materials = require 'maptools.materials'

math.randomseed(os.time())

do
  local cavegen = CaveGenerator(200, 200, 5)

  cavegen:generate()

  local upsampled = cavegen.intermediate:upsample(2)
  local intermediateWithWalls = upsampled:runMarchingSquares(materials.caveFloor)
  intermediateWithWalls:remap(function(k) return k + materials.caveNothing end)

  -- Add details
  intermediateWithWalls:remap(function(k, x, y)
    if k == materials.caveNothing then
      local below = intermediateWithWalls:get(x, y+1)
      if below == materials.caveNorthWall then
        return materials.caveNorthWallHigh
      elseif below == materials.caveInnerNE then
        return materials.caveNEWallHigh
      elseif below == materials.caveInnerNW then
        return materials.caveNWWallHigh
      end
    end 
    return k
  end)

  local rectToString = function(r)
    return string.format("%d,%d,%d,%d", r.x, r.y, r.w, r.h)
  end

  -- Place stalagmites
  local stalagmites = tilesetInfo.info.patches.stalagmites
  intermediateWithWalls:map(function(k, x, y)
    -- choose random stalagmite
    local stalagmitePatch = stalagmites[math.random(#stalagmites)]

    if intermediateWithWalls:squareEquals(x, y, stalagmitePatch.w, stalagmitePatch.h, materials.caveFloor) then
      if math.random() < 0.1 then
        print(x, y, rectToString(stalagmitePatch))
        intermediateWithWalls:layDownPatch(x, y, stalagmitePatch, tilesetInfo)
      end
    end
  end)

  local tilemap = intermediateWithWalls:toTilemap(tilesetInfo)

  tilemap:write('testcave.map')
end
