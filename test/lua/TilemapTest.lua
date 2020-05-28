local Tilemap = require 'tilemap'

local TilemapTest = require 'class'(require 'test.TestBase')

-- TODO test map creation, get/set, load and save
--

function TilemapTest:testCreate()
  local map = Tilemap{w=10, h=10, nlayers=1, tw=0, th=0}

  -- all tiles should be 0
  for y = 0, 9 do
    for x = 0, 9 do
      local info, flags = map:getTileInfo(0, x, y)
      self:expectEquals(0, flags)
      self:assertEquals("table", type(info))
      self:assertEquals("table", type(info.frames))
      self:expectEquals(0, #info.frames)
      self:expectEquals(0, info.flags)
      self:expectEquals("", info.name)
    end
  end
end

function TilemapTest:testGetAndSetTileInfo()
  local map = Tilemap{w=2, h=1, nlayers=1, tw=0, th=0}
  map:addTileInfo{
    flags = 42,
    name = "some name",
    w = 1, h = 2, sx = 3, sy = 4, dx = 5, dy = 6,
    frames = {
      Tilemap.AnimationFrame{tileX = 2, duration = 500},
      Tilemap.AnimationFrame{tileX = 3, duration = 400}
    }
  }

  map:setTileInfoIdxForTile(0, 0, 0, --[[idx=]]1)

  local tileInfo = map:getTileInfo(0, 0, 0)

  self:assertEquals("table", type(tileInfo))
  self:expectEquals(42, tileInfo.flags)
  self:expectEquals("some name", tileInfo.name)
  self:assertEquals("table", type(tileInfo.frames))
  self:assertEquals(2, #tileInfo.frames)
  self:expectEquals(2, tileInfo.frames[1].tileX)
  self:expectEquals(500, tileInfo.frames[1].duration)
  self:expectEquals(3, tileInfo.frames[2].tileX)
  self:expectEquals(400, tileInfo.frames[2].duration)

  self:expectEquals(1, tileInfo.w)
  self:expectEquals(2, tileInfo.h)
  self:expectEquals(3, tileInfo.sx)
  self:expectEquals(4, tileInfo.sy)
  self:expectEquals(5, tileInfo.dx)
  self:expectEquals(6, tileInfo.dy)
end

function TilemapTest:testGetAllTileInfos()
  local map = Tilemap{w=2, h=1, nlayers=1, tw=0, th=0}
  map:addTileInfo{w = 1, h = 2, name='first'}
  map:addTileInfo{w = 3, h = 4, name='second'}
 
  local infos = map:getAllTileInfos()
  self:assertEquals('table', type(infos))
  self:assertEquals(3, #infos)
  self:expectEquals('first', infos[2].name)
  self:expectEquals('second', infos[3].name)
end

function TilemapTest:testSaveAndLoad()
  local map = Tilemap{w=2, h=1, nlayers=1, tw=0, th=0}
  map:addTileInfo{
    flags = 42,
    name = "some name",
    w = 1, h = 2, sx = 3, sy = 4, dx = 5, dy = 6,
    frames = {
      Tilemap.AnimationFrame{tileX = 2, duration = 500},
      Tilemap.AnimationFrame{tileX = 3, duration = 400}
    }
  }

  map:setTileInfoIdxForTile(0, 1, 0, --[[idx=]]1)

  local mapfile = require 'os'.tmpname()
  self:assertTrue(map:write(mapfile))

  local loaded = Tilemap{file=mapfile}
  local tileInfo = loaded:getTileInfo(0, 1, 0)

  self:assertEquals("table", type(tileInfo))
  self:expectEquals(42, tileInfo.flags)
  self:expectEquals("some name", tileInfo.name)
  self:assertEquals("table", type(tileInfo.frames))
  self:assertEquals(2, #tileInfo.frames)
  self:expectEquals(2, tileInfo.frames[1].tileX)
  self:expectEquals(500, tileInfo.frames[1].duration)
  self:expectEquals(3, tileInfo.frames[2].tileX)
  self:expectEquals(400, tileInfo.frames[2].duration)

  self:expectEquals(1, tileInfo.w)
  self:expectEquals(2, tileInfo.h)
  self:expectEquals(3, tileInfo.sx)
  self:expectEquals(4, tileInfo.sy)
  self:expectEquals(5, tileInfo.dx)
  self:expectEquals(6, tileInfo.dy)
end

return TilemapTest
