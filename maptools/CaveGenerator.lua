-- Cave tileset should look like:
-- 
-- outside visible area: black
-- floor: gravelly?
--
local Class = require 'class'
local Set = require 'Set'
local Point = require 'Point'

local IntermediateMap = require 'maptools.IntermediateMap'
local materials = require 'maptools.materials'

local intPoint = function(x, y) return Point(x // 1, y // 1) end

local CaveGenerator = Class()

function CaveGenerator:init(w, h, nrooms)
  self.nrooms = nrooms
  self.intermediate = IntermediateMap{w=w, h=h, initial=materials.caveNothing}
  -- TODO avoid placing rooms too close to the edge

  self.roomSize = 1
  self.jaggedCuts = 4
  self.jagScale = 0.5
  self.carveWidth = 8
end

function CaveGenerator:clip(x, y)
  local xx = math.min(math.max(0, x), self.intermediate.w)
  local yy = math.min(math.max(0, y), self.intermediate.h)
  return xx, yy
end

-- Recursively cuts a zigzagging path from Point |a| to Point |b|. Sets "nextPoint"
-- field on each point to form a linked list starting at |a|.
function CaveGenerator:makeJaggedEdge(nCuts, a, b)
  if nCuts <= 0 then 
    a.nextPoint = b
    return
  end

  -- Choose a random direction and distance
  local midpoint = Point((a.x + b.x) // 2, (a.y + b.y) // 2)

  local angle = math.atan((b.y - a.y) / (b.x - a.x)) + 0.5 * math.pi
  --local angle = math.random() * 2 * math.pi
  local distance = (math.random() - 1) * a:distanceTo(b) * self.jagScale

  -- Find the new middle point and recurse
  local jagPoint = midpoint + Point(math.cos(angle) * distance, math.sin(angle) * distance)
  jagPoint = Point(self:clip(jagPoint.x, jagPoint.y))

  self:makeJaggedEdge(nCuts - 1, a, jagPoint)
  self:makeJaggedEdge(nCuts - 1, jagPoint, b)
end

function CaveGenerator:generate()
  local w, h = self.intermediate.w, self.intermediate.h

  self.roomCenters = {}
  local edges = {}
  local reachable, unreachable = Set(), Set()

  -- Hollow out |nrooms| rooms
  for i = 1, self.nrooms do
    local center = Point(math.random(0.1 * w // 1, 0.9 * w // 1), math.random(0.1 * h // 1, 0.9 * h // 1))
    self.roomCenters[#self.roomCenters+1] = center
    self:makeRoom(center)
    unreachable:insert(i)
  end

  -- determine edges: add edges until every room is reachable
  local roomA = unreachable:random()
  if not roomA then error("no unreachable rooms") end
  unreachable:remove(roomA)
  reachable:insert(roomA)

  while unreachable:size() > 0 do
    local roomB = unreachable:random()
    table.insert(edges, {a=roomA, b=roomB})
    unreachable:remove(roomB)
    reachable:insert(roomB)
    roomA = reachable:random()
  end

  -- subdivide/jag edges
  local jaggedEdges = {}
  for _, edge in ipairs(edges) do
    local a, b = self.roomCenters[edge.a]:copy(), self.roomCenters[edge.b]:copy()
    self:makeJaggedEdge(self.jaggedCuts, a, b)
    table.insert(jaggedEdges, a)
  end

  -- carve passages
  for _, pointA in ipairs(jaggedEdges) do
    while pointA do
      local pointB = pointA.nextPoint
      if pointB then
        self:carvePassage(pointA, pointB)
      end
      pointA = pointB
    end
  end

  -- details
  -- make map
end

local rootHalf = math.sqrt(0.5)

local getSquaresOnLine = function(a, b, callback)
  local nSquaresMax = (a:distanceTo(b) + 1) / rootHalf
  local diff = b - a

  local lastSquare
  for f = 0, 1, (1 / nSquaresMax) do
    local possibleSquare = Point(a.x + f * diff.x, a.y + f * diff.y)
    if possibleSquare ~= lastSquare then
      callback(possibleSquare)
      lastSquare = possibleSquare
    end
  end
end

local halfPi = 0.5 * math.pi

function CaveGenerator:carvePassage(a, b)
  -- Angle b/a rotated 90 degrees
  local dx, dy = (b.x - a.x), (b.y - a.y)
  local razorAngle = math.atan(dy / dx) + halfPi

  local halfWidth = self.carveWidth * 0.5
  local offX, offY = halfWidth * math.cos(razorAngle), halfWidth * math.sin(razorAngle)
  local wingI, wingJ = intPoint(a.x - offX, a.y - offY), intPoint(a.x + offX, a.y + offY)

  local dPoint = Point(dx, dy)
  getSquaresOnLine(wingI, wingJ, function(endPoint)
    getSquaresOnLine(endPoint, endPoint + dPoint, function(innerPoint)
      self.intermediate:set(innerPoint.x // 1, innerPoint.y // 1, materials.caveFloor)
    end)
  end)
end

function CaveGenerator:makeRoom(center)
  local x, y = center.x, center.y

  -- Random walk
  for i = 1, self.roomSize do
    self.intermediate:set(x, y, materials.caveFloor)
    x = x + math.random(-1, 1)
    y = y + math.random(-1, 1)
  end
end

return CaveGenerator
