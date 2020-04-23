local Image = require 'image'
local Engine = require 'engine'
local TestBase = require 'test.TestBase'
local ImageTest = require 'class'(TestBase)

local testFile = __rootdir..'/test/lua/test.png'

local loadTestImage = function(engine)
  return Image{
    file = __rootdir..'/test/lua/test.png',
    engine = engine,
    keepSurface = true
  }
end

function ImageTest:init(...)
  TestBase.init(self, ...)
  self.engine = Engine{}
end

function ImageTest:testThings()
  local img = loadTestImage(self.engine)
  self:expectEquals(4, img.w)
  self:expectEquals(4, img.h)
  
  local r, g, b = 255, 255, 0
  local pixel = img:getPixel(3, 0)
  self:expectEquals(255, pixel.r)
  self:expectEquals(255, pixel.g)
  self:expectEquals(0, pixel.b)
end

function ImageTest:testSavePng()
  local img = loadTestImage(self.engine)
  local tempfile = '/tmp/savepngtest.png'
  assert(img:saveAsPng(tempfile))

  local loaded = Image{
    file = tempfile,
    engine = self.engine,
    keepSurface = true
  }
 
  assert(loaded)
  self:expectEquals(4, loaded.w)
  self:expectEquals(4, loaded.h)
  
  local r, g, b = 255, 255, 0
  local pixel = loaded:getPixel(3, 0)
  self:expectEquals(255, pixel.r)
  self:expectEquals(255, pixel.g)
  self:expectEquals(0, pixel.b)

  --require 'os'.execute('rm '..tempfile)
end

return ImageTest
