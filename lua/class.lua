
local makeClass = function(...)

  -- our class table
  local klass = {
    isA = {}
  }

  klass.isA[klass] = true

  -- copy things from parent classes
  for _, base in ipairs{...} do

    -- copy isA table
    klass.isA[base] = true

    -- copy base class contents
    for k, v in pairs(base) do
      if k == "isA" then
        -- copy isA table
        for isAKey, isAValue in pairs(v) do
          klass.isA[isAKey] = isAValue
        end
      else
        -- shallow copy base class data
        klass[k] = v
      end
    end

  end

  local klassMT = getmetatable(klass) or {}

  -- When klass is called, return new instance
  klassMT.__call = function(klassarg, ...)
    local that = setmetatable({}, {
      -- look up instance methods from klass
      __index = klass
      -- TODO: add option for instance to get its own copies of class fields
    })

    local err = nil
    if that.init then
      _, err = that:init(...)
    end

    if err then
      return nil, err
    end
    return that, err
  end

  setmetatable(klass, klassMT)

  return klass
end

local Class = setmetatable({
  cacheClassMembers = function(instance)
    assert(type(instance) == 'table')
    local mt = getmetatable(instance)
    local classTable = mt.__index
    assert(type(classTable) == 'table')
    for k, v in pairs(classTable) do
      instance[k] = v
    end
  end
}, {
  __call = makeClass
})


return Class
