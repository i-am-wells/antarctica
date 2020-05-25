local ColorMap = require 'maptools.ColorMap'
local ColorMapTest = require 'class'(require 'test.TestBase')

function ColorMapTest:testGetEmpty()
  local map = ColorMap()
  self:expectEquals(nil, map[{r=255, g=255, b=255}])
end

function ColorMapTest:testInit()
  local map = ColorMap{
    [0x010203] = 'first',
    [0x040506] = 'second'
  }

  self:expectEquals('first', map[{r=1, g=2, b=3}])
  self:expectEquals('second', map[{r=4, g=5, b=6}])
end

function ColorMapTest:testGetAndSet()
  local map = ColorMap()
  map[{r=10, g=11, b=12}] = 'surprise'
  self:expectEquals('surprise', map[{r=10, g=11, b=12}])
end

return ColorMapTest
