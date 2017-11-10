
local class = {}

class.deriving = function(...)
    -- our class table
    local klass = {
        initSuper = {},
        isA = {}
    }

    -- copy things from parent classes
    for _, base in pairs{...} do

        -- copy isA table
        klass.isA[klass] = true
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
        local that = {}
        setmetatable(that, {
            -- look up instance methods from klass
            __index = klass
        })

        local err = nil
        if that.init then
            err = that:init(...)
        end

        return that, err
    end

    setmetatable(klass, klassMT)

    return klass
end

class.base = function()
    return class.deriving()
end

return class
