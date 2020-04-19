local log = require 'log'
local Class = require 'class'

local isTest = function(k, v)
  return 
  type(v) == 'function' and 
  type(k) == 'string' and 
  k:sub(1,4):lower() == 'test'
end


local TestBase = Class()


TestBase.success = 'success'
TestBase.failure = 'failure'
TestBase.crash = 'crash'
TestBase.timeout = 'timeout'


function TestBase:init()

  self.results = {}
  -- name of test currently running
  self.currentlyRunning = nil 

  -- 10 * 1000 ms
  self.timeoutDelay = 10000
end


function TestBase:runTests()
  -- Get all methods. We can't iterate directly over the instance table
  -- because it gets its methods by looking them up in the class.
  local mt = getmetatable(self)
  local classTable = mt.__index
  if type(classTable) ~= 'table' then
    log.warning('Failed to get test class table')
    classTable = self
  end

  -- Find all tests
  for k, v in pairs(classTable) do
    if isTest(k, v) then
      self:runTest(k, v)
    end
  end
end


function TestBase:runTest(name, fn)
  log.info('Running %s...', name)

  -- TODO must survive crash!
  if self.setUp then
    self:setUp()
  end
  self.currentlyRunning = name
  self.failedExpect = false

  -- Run and catch errors
  -- TODO crash is misleading
  local finished, errmsg = pcall(fn, self)
  if not finished then
    log.error('Lua error in %s: %s', name, errmsg)
    self.results[name] = TestBase.crash
  elseif self.failedExpect then
    log.error('Test failed: %s', name)
    self.results[name] = TestBase.failure
  else
    self.results[name] = TestBase.success
  end

  -- TODO catch timeout!

  self.currentlyRunning = nil
  if self.tearDown then
    self:tearDown()
  end
end


function TestBase:expect(condition, msg, ...)
  if not condition then
    log.error('Expectation failed: '..msg, ...)
    self.failedExpect = true
    return false
  end
  return true
end


function TestBase:expectEquals(a, b)
  self:expect(a == b, 'expected %s but got %s', tostring(a), tostring(b))
end

function TestBase:assertEquals(a, b)
  assert(a == b, string.format('expected %s but got %s', tostring(a), tostring(b)))
end


function TestBase:logSummary()
  local nSuccess, nFail, nCrash, nTimeout = 0, 0, 0, 0
  for testName, result in pairs(self.results) do
    if result == 'success' then
      nSuccess = nSuccess + 1
      log.setColor('green')
    elseif result == 'failure' then
      nFail = nFail + 1
    elseif result == 'crash' then
      nCrash = nCrash + 1
    elseif result == 'timeout' then
      nTimeout = nTimeout + 1
    end

    if result ~= 'success' then
      log.setColor('red')
    end

    log.info('%s:\t%s', result:upper(), testName)
  end

  log.setColor('default')
  log.info('%d succeeded, %d failed, %d crashed, %d timed out',
  nSuccess, nFail, nCrash, nTimeout)
end

function TestBase:expectTableContentsEqual(tA, tB)
  self:assertEquals('table', type(tA))
  self:assertEquals('table', type(tB))
  for k, v in pairs(tA) do
    if type(v) == 'table' then
      self:expectTableContentsEqual(v, tB[v])
    else
      self:expectEquals(v, tB[v])
    end
  end
end

return TestBase

