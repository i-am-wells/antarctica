local testModules = {
  'test.lua.LogTest',
  'test.lua.ClassTest',
  'test.lua.RopeTest',
}

local log = require 'log'

log.configure{
  level = log.levels.info
}

for _, path in ipairs(testModules) do
  local testClass = assert(require(path))
  local testClassInstance = testClass()
  log.info('=== Running %s ===', path)

  log.setIndent(4)

  testClassInstance:runTests()


  log.setIndent(0)
  log.info('')
  log.info('=== Summary ===')

  testClassInstance:logSummary()

  log.info('')
end

