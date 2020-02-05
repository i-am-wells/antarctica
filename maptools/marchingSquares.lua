local Set = require 'Set'

local makeTransition = function(tilemap, transitions, a, b, c, d, z, x, y)
  local trans, reverse = transitions[a], false
  if trans then trans = trans[z] end

  if not trans then
    trans, reverse = transitions[z], true
    if trans then trans = trans[a] end
    if not trans then return end
  end

  local tx, ty = 0, 0
  if not reverse then
    if d == z then tx = tx + 1 end
    if c == z then tx = tx + 2 end
    if b == z then ty = ty + 1 end
  else
    tx, ty = 0, 2
    if d == a then tx = tx + 1 end
    if c == a then tx = tx + 2 end
    if b == a then ty = ty + 1 end
  end

  tilemap:setTile(--[[layer=]]0, x, y, trans.x + tx, trans.y + ty)
end

return function(intermediateMap, tilesetInfo, tilemap)
  local map, transitions = intermediateMap, tilesetInfo.transitions

  for y = 1, map.h do
    for x = 1, map.w do
      local a, z = assert(map:get(x, y)), nil

      local b = map:get(x+1, y) or a
      if b ~= a then 
        z = b 
      end

      local c = map:get(x, y+1) or a
      if z then
        if c ~= a and c ~= z then
          goto continue
        end
      else
        if c ~= a then
          z = c
        end
      end

      local d = map:get(x+1, y+1) or b
      if z then
        if d ~= a and d ~= z then
          goto continue
        end
      else
        if d ~= a then
          z = d
        else
          goto continue
        end
      end

      makeTransition(tilemap, transitions, a, b, c, d, z, x-1, y-1)
      ::continue::
    end
  end

end
  
