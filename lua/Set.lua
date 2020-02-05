local math = require 'math'
local Class = require 'class'

local Set = Class()

function Set:init(members)
  self.members = {}
  self.count = 0

  if type(members) == 'table' then
    for _, thing in ipairs(members) do
      self:insert(thing)
    end
  end
end

function Set:has(thing)
  if thing == nil then return end
  return self.members[thing] or false
end

function Set:insert(thing)
  if thing == nil then return end

  if not self:has(thing) then
    self.members[thing] = true
    self.count = self.count + 1
  end
end

function Set:remove(thing)
  if thing ~= nil then
    self.members[thing] = nil
    self.count = self.count - 1
  end
end

function Set:size()
  return self.count
end

-- avoid
function Set:random()
  if self.count == 0 then
    return nil
  end

  local choice = math.random(self.count)
  local i = 1
  for thing, _ in pairs(self.members) do
    if i == choice then
      return thing
    end
    i = i + 1
  end
end

-- avoid
function Set:asArray()
  local array = {}
  for thing, _ in pairs(self.members) do
    array[#array+1] = thing
  end
  return array
end

return Set
