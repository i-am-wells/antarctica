local Util = require 'Util'

return require 'class'(require 'test.TestBase', {
  testBindPartial = function(self)
    local x, y, z, w
    local foo = function(a, b, c, d)
      x = a
      y = b
      z = c
      w = d
    end

    local boundPartial = Util.bind(foo, 1, 2)
    boundPartial(3, 4)

    self:expectEquals(1, x)
    self:expectEquals(2, y)
    self:expectEquals(3, z)
    self:expectEquals(4, w)
  end,

  testBindFull = function(self)
    local x, y, z, w
    local foo = function(a, b, c, d)
      x = a
      y = b
      z = c
      w = d
    end

    local boundFull = Util.bind(foo, 1, 2, 3, 4)
    boundFull()

    self:expectEquals(1, x)
    self:expectEquals(2, y)
    self:expectEquals(3, z)
    self:expectEquals(4, w)
  end,
})
