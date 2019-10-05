local math = require 'math'
local string = require 'string'

local Class = require 'class'

local Point = Class()

local PointMT = {}
PointMT.__eq = function(a, b)
  return a.x == b.x and a.y == b.y
end

PointMT.__add = function(a, b)
  return Point(a.x + b.x, a.y + b.y)
end

PointMT.__sub = function(a, b)
  return Point(a.x - b.x, a.y - b.y)
end

PointMT.__tostring = function(point)
  return string.format('(%s, %s)', tostring(point.x), tostring(point.y))
end

function Point:init(x, y)
  local mt = getmetatable(self)
  for k, v in pairs(PointMT) do
    mt[k] = v
  end
  setmetatable(self, mt)

  self.x = x
  self.y = y
end

function Point:distanceTo(other)
  local dx, dy = math.abs(self.x - other.x), math.abs(self.y - other.y)
  return math.sqrt(dx * dx + dy * dy)
end

function Point:copy()
  return Point(self.x, self.y)
end

return Point
