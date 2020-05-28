local Tilemap = require 'tilemap'

local filename = __rootdir .. '/res/tiles/waves.png'
local tw, th = 16, 16

local frameData = {
  {x = 0, y = 0, duration = 20},
  {x = 10, y = 0, duration = 20},
  {x = 20, y = 0, duration = 20},
  {x = 30, y = 0, duration = 20},
  {x = 0, y = 10, duration = 20},
  {x = 10, y = 10, duration = 20},
  {x = 20, y = 10, duration = 20},
  {x = 30, y = 10, duration = 20},
}

local makeFrames = function(info)
  local frames = {}
  for i, frame in ipairs(frameData) do
    frames[i] = Tilemap.AnimationFrame{
      duration = frame.duration,
      x = info.sx + frame.x * tw,
      y = info.sy + frame.y * th,
    }
  end
  return frames
end

local makeTileInfo = function(sx, sy, w, h)
  local info = Tilemap.TileInfo{
    name = filename,
    w = tw * w,
    h = th * h,
    sx = tw * sx,
    sy = th * sy 
  }
  info.frames = makeFrames(info)
  return info
end

return {
  SETight = makeTileInfo(3, 3, 2, 2),
  SWTight = makeTileInfo(5, 3, 2, 2),
  NETight = makeTileInfo(3, 5, 2, 2),
  NWTight = makeTileInfo(5, 5, 2, 2),

  NWOuter = makeTileInfo(1, 1, 2, 1),
  NEOuter = makeTileInfo(7, 1, 2, 1),
  SWOuter = makeTileInfo(1, 8, 2, 1),
  SEOuter = makeTileInfo(7, 8, 2, 1),

  NWInner = makeTileInfo(2, 2, 2, 1),
  NEInner = makeTileInfo(6, 2, 2, 1),
  SWInner = makeTileInfo(2, 7, 2, 1),
  SEInner = makeTileInfo(6, 7, 2, 1),

  north = makeTileInfo(4, 0, 1, 2),
  south = makeTileInfo(4, 8, 1, 2),
  east = makeTileInfo(8, 4, 2, 1),
  west = makeTileInfo(0, 4, 2, 1),

  NNWCorner = makeTileInfo(3, 0, 1, 2),
  NNECorner = makeTileInfo(6, 0, 1, 2),
  ENECorner = makeTileInfo(8, 3, 2, 1),
  ESECorner = makeTileInfo(8, 6, 2, 1),
  SSECorner = makeTileInfo(6, 8, 1, 2),
  SSWCorner = makeTileInfo(3, 8, 1, 2),
  WSWCorner = makeTileInfo(0, 6, 2, 1),
  WNWCorner = makeTileInfo(0, 3, 2, 1),
}
