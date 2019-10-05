local Class = require 'class'
local Stack = require 'Stack'

local Queue = Class()

function Queue:init()
  self.inStack = Stack()
  self.outStack = Stack()
end

function Queue:push(thing)
  self.inStack:push(thing)
end

function Queue:pop()
  if #self.outStack == 0 then
    while not self.inStack:empty() do
      self.outStack:push(self.inStack:pop())
    end
  end

  return self.outStack:pop()
end

function Queue:empty()
  return self.inStack:empty() and self.outStack:empty()
end

return Queue
