local math = require 'math'

local pi = 3.141592654

local util
util = {
  getDirection = function(dx, dy)
    local angle = math.atan(dy, dx) * 180 / pi
    if angle >= -45 and angle < 45 then
      return 'east'
    elseif angle >= 45 and angle < 135 then
      return 'south'
    elseif angle >= 135 or angle < -135 then
      return 'west'
    elseif angle >= -135 and angle < -45 then
      return 'north'
    end
  end,

  getOppositeDirection = function(dx, dy)
    return ({
      north = 'south',
      south = 'north',
      east = 'west',
      west = 'east'
    })[util.getDirection(dx, dy)]
  end
}

return util
