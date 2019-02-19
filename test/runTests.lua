local testModules = {
    --'lua.log_test',
    'lua.class_test',
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

