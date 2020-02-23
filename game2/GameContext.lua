local Class = require 'class'
local Context = require 'ui.Context'

local GameContext = Class(Context)

function GameContext:init(argtable)
  if __dbg then
    assert(argtable.state)
  end

  
end

return GameContext
