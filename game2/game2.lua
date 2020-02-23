local ContextStack = require 'ui.ContextStack'
local GameContext = require 'ui.GameContext'

return function(engine, state)
  local contextStack = ContextStack{
    engine = engine,
    initialContext = GameContext{
      state = state
    }
  }
  engine:run
end
