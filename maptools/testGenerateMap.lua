local package = require 'package'
package.path = package.path..';./lua/?.lua'

local math = require 'math'
local os = require 'os'

local HillsideMapGenerator = require 'maptools.HillsideMapGenerator'

math.randomseed(os.time())

do
  local outputFile = arg[2] or 'testGenerated.map'
  print('Generating '..outputFile)

  local w, h = 50, 50

  local mapgen = HillsideMapGenerator(w, h)

  local mapping0 = mapgen:make16Mapping(0, 0)
  local mapping1 = mapgen:make16Mapping(4, 0)
  local map = mapgen:generate(mapping0, mapping1)
  map:write(outputFile)
end
