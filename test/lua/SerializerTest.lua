local Serializer = require 'Serializer'

local TestBase = require 'test.TestBase'
local SerializerTest = require 'class'(TestBase)

function SerializerTest:init(...)
  TestBase.init(self, ...)
  self.serializer = Serializer()
end

function SerializerTest:testSimpleTypes()
  -- nil
  self:expectEquals('nil', self.serializer:serializeToString(nil))

  -- booleans
  self:expectEquals('true', self.serializer:serializeToString(true))
  self:expectEquals('false', self.serializer:serializeToString(false))

  -- numbers
  self:expectEquals('1', self.serializer:serializeToString(1))
  self:expectEquals('-2', self.serializer:serializeToString(-2))
  self:expectEquals('0.33', self.serializer:serializeToString(0.33))

  -- things we can't print
  local fn = function() end
  local fnPrefix = 'function: 0x'
  self:expectEquals(fnPrefix, self.serializer:serializeToString(fn):sub(1, #fnPrefix))

  local co = require 'coroutine'.create(fn)
  local coPrefix = 'thread: 0x'
  self:expectEquals(coPrefix, self.serializer:serializeToString(co):sub(1, #coPrefix))
end

function SerializerTest:testString()
  self:expectEquals("'abc'", self.serializer:serializeToString('abc'))
  self:expectEquals("'abc\\nabc'", self.serializer:serializeToString('abc\nabc'))
  self:expectEquals("'abc\"def\\''", self.serializer:serializeToString('abc"def\''))
end

function SerializerTest:testSimpleTable()
  local t = {}
  self:expectEquals('{\n}', self.serializer:serializeToString(t))
  
  t.a = 1
  self:expectEquals("{\n  ['a'] = 1,\n}", self.serializer:serializeToString(t))
  
  t[2] = 'asdf'
  serialized = self.serializer:serializeToString(t)
  self:expectEquals('{', serialized:sub(1, 1))
  self:expectTrue(serialized:find("  ['a'] = 1,", 1, true) ~= nil)
  self:expectTrue(serialized:find("  [2] = 'asdf',", 1, true) ~= nil)
  self:expectEquals('}', serialized:sub(#serialized))
end

function SerializerTest:testTableInTable()
  local t = {{x=1}}
  self:expectEquals(
    "{\n  [1] = {\n    ['x'] = 1,\n  },\n}",
    self.serializer:serializeToString(t))

end

return SerializerTest

