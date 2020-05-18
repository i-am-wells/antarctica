local Tilemap = require 'tilemap'

local TilemapTest = require 'class'(require 'test.TestBase')

-- TODO test map creation, get/set, load and save
--

function TilemapTest:testCreate()
  local map = Tilemap{w=10, h=10, nlayers=1}

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
  local map = Tilemap{w=2, h=1, nlayers=1}
  map:addTileInfo{
    flags = 42,
    name = "some name",
    frames = {
      Tilemap.AnimationFrame{tileX = 2, duration = 500},
      Tilemap.AnimationFrame{tileX = 3, duration = 400}
    }
  }

  map:setTileInfoIdxForTile(0, 0, 0, --[[idx=]]1)

  -- TODO test tile data
  local tileInfo, data = map:getTileInfo(0, 0, 0)

  print("printing tile info")
  for k, v in pairs(tileInfo) do print(k, v) end

  self:assertEquals("table", type(tileInfo))
  self:expectEquals(42, tileInfo.flags)
  self:expectEquals("some name", tileInfo.name)
  self:assertEquals("table", type(tileInfo.frames))
  self:assertEquals(2, #tileInfo.frames)
  self:expectEquals(2, tileInfo.frames[1].tileX)
  self:expectEquals(500, tileInfo.frames[1].duration)
  self:expectEquals(3, tileInfo.frames[2].tileX)
  self:expectEquals(400, tileInfo.frames[2].duration)
end

return TilemapTest
