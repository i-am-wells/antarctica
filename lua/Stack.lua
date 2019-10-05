local Class = require 'class'

local Stack = Class()

function Stack:init()
  self.data = {}
end

function Stack:push(thing)
  table.insert(self.data, thing)
end

function Stack:pop()
  local thing = self.data[#self.data]
  self.data[#self.data] = nil
  return thing
end

function Stack:empty()
  return #self.data == 0
end

return Stack
