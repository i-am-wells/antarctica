
-- which resource goes with which map, named locations, etc.
return {
  mapdir = __rootdir..'/res/maps/',
  maps = {
    antarcticaSurface = {
      file = 'antarctica.map',
      tileImage = __rootdir..'/res/forest-16x16.png',
      tileW = 16,
      tileH = 16,
      -- TODO should be dark
      background = {r=255, g=255, b=255},

      -- TODO: change how this works
      warps = {
        -- 502, 905
        --[[
        _502_905_s = {map='home', x=14, y=17},
        _516_913_s = {map='house2', x=14, y=17},
        _523_904_s = {map='house1', x=14, y=17},
        _498_888_s = {map='house3', x=14, y=17},
        _446_915_s = {map='tavern', x=22, y=18},
        _477_894_s = {map='grocery', x=13, y=23},
        _464_905_s = {map='advisoryHall', x=23, y=38},

        -- run hook water0
        _493_945_n = 'water0'
        --]]

        -- TODO
        -- home
        -- tavern
      },

      water0 = function(game, hero)
        -- TODO jump into water
        hero:dive()
        -- TODO
      end

    },

    home = {
      file = 'home-new.map',
      tileImage = 'res/spritesnew-16x16.png',
      tileW = 16,
      tileH = 16,
      background = {r=20, g=12, b=28},

      warps = {
        -- TODO location
        _14_17_n = {map='antarcticaSurface', x=502, y=906}
      }
    },

    house1 = {
      file = 'house1.map',
      tileImage = 'res/spritesnew-16x16.png',
      tileW = 16,
      tileH = 16,
      background = {r=20, g=12, b=28},

      warps = {
        _14_17_n = {map='antarcticaSurface', x=523, y=905}
      }
    },


    house2 = {
      file = 'house2.map',
      tileImage = 'res/spritesnew-16x16.png',
      tileW = 16,
      tileH = 16,
      background = {r=20, g=12, b=28},

      warps = {
        _14_17_n = {map='antarcticaSurface', x=516, y=914}
      }
    },

    house3 = {
      file = 'house3.map',
      tileImage = 'res/spritesnew-16x16.png',
      tileW = 16,
      tileH = 16,
      background = {r=20, g=12, b=28},

      warps = {
        _14_17_n = {map='antarcticaSurface', x=498, y=889}
      }
    },
    grocery = {
      file = 'grocery.map',
      tileImage = 'res/spritesnew-16x16.png',
      tileW = 16,
      tileH = 16,
      background = {r=20, g=12, b=18},

      warps = {
        -- TODO location
        _13_23_n = {map='antarcticaSurface', x=477, y=895}

      }
    },



    tavern = {
      file = 'bar.map',
      tileImage = 'res/spritesnew-16x16.png',
      tileW = 16,
      tileH = 16,
      background = {r=20, g=12, b=18},

      warps = {
        -- TODO location
        _22_18_n = {map='antarcticaSurface', x=446, y=916}

      }
    },

    advisoryHall = {
      file = 'advisoryhall.map',
      tileImage = 'res/spritesnew-16x16.png',
      tileW = 16,
      tileH = 16,
      background = {r=20, g=12, b=18},

      warps = {
        -- TODO location
        _23_38_n = {map='antarcticaSurface', x=464, y=906}

      }
    }


  }
}

