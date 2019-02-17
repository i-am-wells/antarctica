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

    load_image = function()
        local engine = Engine{}

        local image = Image{file='res/terrain.png'}

        assert(image._image ~= nil, 'failed to load image')
    end,

    draw_image = function()
        local engine = Engine{}

        local image = Image{file='res/terrain.png'}

        -- TODO draw image and compare engine output with another image
    end,

    create_map = function()
        local tilemap = Tilemap{nlayers=1, w=1,h=1}

        assert(tilemap._tilemap ~= nil, 'failed to create tile map')
        assert(tilemap.nlayers == 1, 'wrong number of layers')
        assert(tilemap.w == 1, 'wrong width')
        assert(tilemap.h == 1, 'wrong height')
    end,

    save_and_load_map = function()
        local tilemap = Tilemap{nlayers=1, w=1,h=1}
        
        tilemap:write('/tmp/testmapfile.map');
        
        local newtilemap = Tilemap{filename='/tmp/testmapfile.map'}

        assert(tilemap._tilemap ~= nil, 'failed to load map file')
        assert(tilemap.nlayers == 1, 'wrong number of layers')
        assert(tilemap.w == 1, 'wrong width')
        assert(tilemap.h == 1, 'wrong height')
    end,

    draw_map = function()
        -- TODO
    end,


}

for name, fn in pairs(tests) do
    print('running '..name..'...')
    fn()
end
