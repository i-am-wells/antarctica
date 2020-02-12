local Penguin = require 'game.penguin'
-- Default new game state.

local tileW, tileH = 16, 16

return {
  tileW = tileW,
  tileH = tileH,
  hero = {
    mapName = 'antarcticaSurface',
    x = 502 * tileW,
    y = 907 * tileH,
    layer = 1,

    class = 'game.hero',
    channel = 0, -- TODO

    data = {
      -- TODO set name
      name = 'Vic',
      inventoryItems = {
        {class='game.items.scrapSteel', data={variety=3}}
      },
      accessory = Penguin.accessories.backpack
    },
  },

  objects = {
    antarcticaSurface = {
      -- TODO NPCs
      {
        class = 'game.penguin',
        x = 507 * tileW,
        y = 907 * tileH,
        layer = 1,

        data = {name='Regina', says="Hi there! You must be young Damo's cousin from Halley. Welcome to New Dunedin! I own the Kiwi at the west edge of town."}
      },
      {
        class = 'game.penguin',
        x = 507 * tileW,
        y = 918 * tileH,
        layer = 1,

        data = {name='Philip', says='...'}
      },
      {
        class = 'game.penguin',
        x = 486 * tileW,
        y = 879 * tileH,
        layer = 1,

        data = {
          name='Marsha', 
          says="Sorry, can't let anyone through today! Leopard seals are on the prowl.",
          accessory = Penguin.accessories.policeHat
        }
      },
      {
        class = 'game.penguin',
        x = 476 * tileW,
        y = 917 * tileH,
        layer = 1,

        data = {
          name='Paul', 
          says="You must be Ruth's other grandkid. Welcome! My job is to keep New Dunedin safe -- please don't make my job any harder than it has to be.",
          accessory = Penguin.accessories.policeHat
        }
      },
      {
        class = 'game.sign',
        x = 504 * tileW,
        y = 906 * tileH,
        layer = 1,

        data = {name="Ruth's House", says='"Bless this house with love and chowder"'}
      },
      {
        class = 'game.penguin',
        x = 493 * tileW,
        y = 949 * tileH,
        layer = 1,
        data = {
          name='Pa Hackett',
          says="Looks like good fishing weather today."
        }
      },

      --[[
      {
      class = 'game.leopardSeal',
      x = 492 * tileW,
      y = 939 * tileH,
      layer = 1,
      data = {
      name='Alfred Seal',
      says="Wait, stop! I promise I won't eat you!"
      }
      },
      --]]

      --[[
      {
      class = 'game.fish',
      x=505*16,
      y=908*16,
      layer=0
      }
      ]]--

      --
      --
      -- TODO items
      {
        class = 'game.items.scrapSteel',
        x = 501 * tileW,
        y = 924 * tileH,
        layer = 1,

        data = {variety = 1, says='asdf'}
      },
      {
        class = 'game.items.scrapSteel',
        x = 497 * tileW,
        y = 934 * tileH,
        layer = 1,

        data = {variety = 2, says='yuio'}
      },
      {
        class = 'game.items.grandmasGuide',
        x = 485 * tileW,
        y = 929 * tileH,
        layer = 1,
        data={says='qwporut'}
      }
      -- TODO props
    },
    grocery = {
      {
        class = 'game.penguin',
        x = 16 * tileW,
        y = 19 * tileH,
        layer = 1,

        data = {
          name='Albert', 
          says="I haven't had a delivery from my supplier in weeks. I wonder if something terrible has happened...",
          accessory = Penguin.accessories.brownApron
        }

      }
    },
    home = {
      {
        class = 'game.penguin',
        x = 13 * tileW,
        y = 13 * tileH,
        layer = 1,

        data = {
          name='Grandma', 
          says="Have you seen Damo? I sent him for fish hours ago!",
          accessory = Penguin.accessories.grandma
        }
      }
    },

    advisoryHall = {
      {
        class = 'game.penguin',
        x = 23 * tileW,
        y = 34 * tileH,
        layer = 1,

        data = {
          name='Lord Mayor', 
          says="Welcome to New Dunedin, neighbor! I'm Mayor Benjamin and I hope I can count on your support in November.",
          accessory = Penguin.accessories.mayorHat
        }
      }

    },
    house3 = {
      {
        class = 'game.penguin',
        x = 15 * tileW,
        y = 11 * tileH,
        layer = 1,
        data = {
          name='Ma Hackett', 
          says="Settle down, kids!      ...    No, I haven't seen Damo. Probably playing hooky again. Are you the cousin he was talking about?",
          accessory = Penguin.glasses
        }
      },
      {
        class = 'game.penguinChick',
        x = 13 * tileW,
        y = 13 * tileH,
        layer = 1,
        data = {
          name='Micah', 
          says="We used to have a different teacher but he was eaten. Now Ma is the teacher.",
        }
      },
      {
        class = 'game.penguinChick',
        x = 15 * tileW,
        y = 13 * tileH,
        layer = 1,
        data = {
          name='Susan', 
          says="I want to go to university waaaay far away, just like Ma did!  ...   Why would she move here?",
        }
      },
      {
        class = 'game.penguinChick',
        x = 15 * tileW,
        y = 14 * tileH,
        layer = 1,
        data = {
          name='Elizabeth', 
          says="...",
        }
      }
    },
    tavern = {
      {
        class = 'game.penguin',
        x = 23 * tileW,
        y = 13 * tileH,
        layer = 1,

        data = {
          name='Oscar', 
          says="Do I own the Kiwi? No, Regina does. I work for her.",
          accessory = Penguin.accessories.whiteApron
        }
      },
      {
        class = 'game.penguin',
        x = 22 * tileW,
        y = 15 * tileH,
        layer = 1,

        data = {
          name='Horvath', 
          says="Hey, friend. Are you new in town?",
        }
      },
      {
        class = 'game.penguin',
        x = 15 * tileW,
        y = 13 * tileH,
        layer = 1,

        data = {
          name='Alice', 
          says="I've been exploring a cave northwest of here. You shouldn't enter a cave without a buddy and three sources of light!",
          accessory = Penguin.accessories.minerHat
        }
      },

    },
  },

  controlMap = {
    D = 'goEast',
    W = 'goNorth',
    A = 'goWest',
    S = 'goSouth',
    Escape = 'quit',
    J = 'slide',
    K = 'interact',
    I = 'inventory'
  }
}

