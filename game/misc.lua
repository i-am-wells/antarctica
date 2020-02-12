local math = require 'math'

local misc = {}

local townNames = {
  first = {'Cold', 'Berg', 'Frost', 'Fish', 'Egg', 'Sleet'},
  last = {'burg', 'town', 'ville', 'borough', 'chester', 'shire', 'ham'}
}


function misc.genTownName(taken)
  local name = nil
  while (name == nil) or taken[name] do
    local firstIdx = math.random() * #townNames.first // 1 + 1
    local lastIdx = math.random() * #townNames.last // 1 + 1

    name = townNames.first[firstIdx]..townNames.last[lastIdx]
  end

  return name
end

return misc
