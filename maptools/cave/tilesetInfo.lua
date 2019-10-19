local Point = require 'Point'
local Rect = require 'Rect'
local TilesetInfo = require 'maptools.TilesetInfo'

return TilesetInfo{
  file = "cave-16x16.png",
  tileWidth = 16,
  tileHeight = 16,
  tiles = {
    caveNothing = Point(0, 0),
    caveFloor = {Point(1, 4), Point(2, 4), Point(3, 4)},

    caveNorthWallHigh = Point(2, 2),
    caveNEWallHigh = Point(6, 0),
    caveNWWallHigh = Point(4, 0),

    -- TODO
    caveX1 = Point(0, 0),
    caveX2 = Point(0, 0),

    caveEastWall = {Point(1, 1), Point(6, 2)},
    caveNorthWall = {Point(2, 3), Point(5, 1)},
    caveWestWall = {Point(3, 1), Point(4, 2)},
    caveSouthWall = {Point(2, 0), Point(5, 4)},
   
    caveInnerNE = Point(6, 1),
    caveInnerNW = Point(4, 1),
    caveInnerSW = Point(4, 4),
    caveInnerSE = Point(6, 4),

    caveOuterNE = Point(1, 3),
    caveOuterNW = Point(3, 3),
    caveOuterSW = Point(3, 0),
    caveOuterSE = Point(1, 0),
  },
  walkable = {
    caveFloor = true
  },
  patches = {
    stalagmites = {
      Rect(2, 5, 2, 2),
      Rect(4, 5, 1, 2),
      Rect(5, 6, 1, 1),
    },
  }
}
