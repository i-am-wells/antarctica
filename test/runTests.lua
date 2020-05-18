local testModules = {
  'test.lua.LogTest',
  'test.lua.ClassTest',
  'test.lua.RopeTest',
  'test.lua.SerializerTest',
  'test.lua.ImageTest',
  'test.lua.TilemapTest',
}

local log = require 'log'

log.configure{
  level = log.levels.info
}

local filter = arg[1]
if filter then
  log.info('Running with filter: %s', filter)
else
  log.info('Running all tests')
  filter = '.*'
end

for _, path in ipairs(testModules) do
  local testClass = assert(require(path))
  local testClassInstance = testClass()
  log.info('=== Running %s ===', path)

  log.setIndent(4)

  testClassInstance:runTests(path, filter)

  log.setIndent(0)
  log.info('')
  log.info('=== Summary ===')

  testClassInstance:logSummary()

  log.info('')
end

