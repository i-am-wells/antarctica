local io = require 'io'
local os = require 'os'
local package = require 'package'

local Class = require 'class'
local TestBase = require 'test.TestBase'

local LogTest = Class(TestBase)


function LogTest:setUp()
  package.loaded.log = nil
  self.log = require 'log'
end

function LogTest:tearDown()
  self.log = nil
end

function LogTest:testInitialLogConfig()
  assert(self.log, 'failed to require log')

  self:expectEquals(1, self.log.level)
  self:expectEquals(true, self.log.stderr)
  self:expectEquals(nil, self.log.filename)
  self:expectEquals(nil, self.log.file)
end

function LogTest:testLogToFile()
  assert(self.log, 'failed to require log')

  self.log.configure{
    level = self.log.levels.debug,
    stderr = true,
    filename = 'tmp.log'
  }

  self.log.fatal('test fatal')
  self.log.error('test error')
  self.log.warning('test warning')
  self.log.info('test info')
  self.log.debug('test debug')

  self.log.close()

  local expectedLog = [[
F test fatal
E test error
W test warning
I test info
D test debug
]]
  local expectedLength = #expectedLog
  local logfile = assert(io.open('tmp.log', 'r'))
  local actualLog = logfile:read(expectedLength)
  logfile:close()

  self.log.configure{
    level = self.log.levels.info
  }

  self:expectEquals(expectedLog, actualLog)

end

return LogTest
