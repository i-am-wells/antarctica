local Class = require 'class'
local TestBase = require 'test.testBase'

local ClassTest = Class(TestBase)

function ClassTest:testBaseClass()
  local baseClass = Class()

  self:expectEquals('table', type(baseClass))
  self:expectEquals('table', type(baseClass.isA))
  self:expect(baseClass.isA[baseClass], 'baseClass is a baseClass')

  local instance = baseClass()
  self:expectEquals('table', type(baseClass))
  self:expect(instance.isA[baseClass], 'baseClass instance is a baseClass')
end

function ClassTest:testChildClass()
  local baseClass = Class()
  baseClass.init = function(slf) end
  baseClass.prop = 'asdfasdf'

  local childClass = Class(baseClass)
  self:expectEquals(baseClass.init, childClass.init)
  self:expectEquals(baseClass.prop, childClass.prop)

  self:expect(childClass.isA[childClass], 'childClass is a childClass')
  self:expect(childClass.isA[baseClass], 'childClass is a baseClass')

  self:expect(not baseClass.isA[childClass])
end

function ClassTest:testChildClassWithMultipleParents()
  local baseClass1, baseClass2 = Class(), Class()
  baseClass1.prop = 'asdf'
  baseClass2.prop = 'qwer'

  local childClass = Class(baseClass1, baseClass2)
  self:expect(childClass.isA[baseClass1])
  self:expect(childClass.isA[baseClass2])

  self:expectEquals(baseClass2.prop, childClass.prop)
end

return ClassTest
