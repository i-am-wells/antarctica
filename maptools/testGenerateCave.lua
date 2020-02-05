local package = require 'package'
package.path = package.path..';./lua/?.lua'

local math = require 'math'
local os = require 'os'

local CaveGen = require 'game.cavegen'

do
  local cg = CaveGen{
    w = 50, h = 50, nlayers = 1
  }

  local map = cg:generate()

  map:write('someCave.map')
end
