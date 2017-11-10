-- Unit testing for antarctica

local ant = require 'antarctica'

local Engine = require 'engine'
local Image = require 'image'

local assertequal = function(actual, expected, name)
    assert(a == b, 'expected '..name..' to be '..tostring(expected)..' but got '..tostring(actual))
end




local tests = {
    create_engine = function()
        -- create an engine with default values
        local engine = Engine{}
        assert(engine._engine ~= nil, 'failed to create engine')
        assertequal(engine.title, 'antarctica', 'engine title')
        
        -- TODO check position, size, window flags

        local engine2 = Engine{title='test'}
        assert(engine._engine ~= nil, 'failed to create engine')
        assertequal(engine.title, 'test', 'engine title')

    end,

    -- TODO more tests
}

for name, fn in pairs(tests) do
    print('running '..name..'...')
    fn()
end
