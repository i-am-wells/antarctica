local Image = require 'image'
local Tilemap = require 'tilemap'
local Set = require 'Set'
local log = require 'log'

return {
  -- want imagePath, colorToTileinfo, layers, tw, th
  createTilemapFromImage = function(arg) 
    local image, err = Image{
      engine = arg.engine or require 'engine'(),
      file = arg.imagePath,
      keepSurface = true
    }
    if not image then
      error(err)
    end

    local tilemap = Tilemap{
      nlayers = arg.layers or 1,
      w = image.w,
      h = image.h,
      tw = arg.tw,
      th = arg.th
    }

    local tileInfoToIdx, nextIdx = {}, 1

    for y = 0, image.h - 1 do
      for x = 0, image.w - 1 do
        local color = image:getPixel(x, y)
        local tileInfo = arg.colorToTileinfo[color]
        if tileInfo then
          -- add tile info if needed
          if not tileInfoToIdx[tileInfo] then
            tileInfoToIdx[tileInfo] = nextIdx
            nextIdx = nextIdx + 1
            tilemap:addTileInfo(tileInfo)
          end

          -- set tile
          tilemap:setTileInfoIdxForTile(--[[layer=]]0, x, y, tileInfoToIdx[tileInfo])
        else
          log.error('unknown color r=%s g=%s b=%s', color.r, color.g, color.b)
        end
        -- If there's no matching tile info, continue without setting anything.
      end
    end

    return tilemap
  end
}
