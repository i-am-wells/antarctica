local Rope = require 'Rope'

local TestBase = require 'test.TestBase'
local RopeTest = require 'class'(TestBase)

function RopeTest:testEmpty()
  self:expectEquals('', Rope():join())
end

function RopeTest:testAdd()
  local rope = Rope()
  rope:add('abc')
  self:expectEquals('abc', rope:join())

  rope:add('def')
  rope:add('ghi')
  self:expectEquals('abcdefghi', rope:join())
end

function RopeTest:testInit()
  self:expectEquals('abc', Rope('a', 'bc'):join())
end

function RopeTest:testSplice()
  local rope1 = Rope('a', 'bc')
  local rope2 = Rope('de', 'f')
  rope1:splice(rope2)
  self:expectEquals('abcdef', rope1:join())
end

return RopeTest
