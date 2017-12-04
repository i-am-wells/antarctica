
local ant = require 'antarctica'
local Tilemap = require 'tilemap'
local Image = require 'image'


-- create a rect table
local rect = function(x, y, w, h)
    return {x=x, y=y, w=w, h=h}
end
    


local editor = function(map, tilefile, filename)
    local Engine = require 'engine'
    
    -- Create a window
    local windowW, windowH = 640, 480
    local engine, err = Engine{
        title='map editor - '..filename,
        w = windowW,
        h = windowH,
        windowflags = 0 -- ant.engine.fullscreen
    }
    if err then
        return error(err)
    end
    
    -- TODO get tile dimensions from user
    local tileset, err = Image{engine=engine, file=tilefile, tilew=16, tileh=16}
    if err then
        printusage("Couldn't load tile set: "..err)
        return
    end



    --
    -- State
    --
    local view = rect(0, 0, windowW, windowH)
    
    local palettesel = rect(0, 0, 1, 1)
    local mapsel = rect(0, 0, 1, 1)
    
    local mouserect = rect(0, 0, tileset.tw, tileset.th)

    local editinglayer = 0
    local showtileset = false
    local shift, ctrlkey = false, false
    local selecting = false

    local showflags = false
    local clearingflags = false

    local flagmask = ant.tilemap.bumpnorthflag
        | ant.tilemap.bumpsouthflag
        | ant.tilemap.bumpeastflag
        | ant.tilemap.bumpwestflag

    print(flagmask)

    local undostack = {}

    --
    -- Controller
    --
    
    -- convert between map and screen coordinates
    local screentomap = function(x, y)
        local mapx = (view.x + x) // tileset.tw
        local mapy = (view.y + y) // tileset.th
        return mapx, mapy
    end

    local maptoscreen = function(x, y)
        local screenx = x * tileset.tw
        local screeny = y * tileset.th
        return screenx, screeny
    end

    local ctrl
    ctrl = {
        set_tiles = function(layer, isfirst)
            ctrl.pushundo(isfirst)

            for y = 0, (palettesel.h - 1) do
                local mapy = mapsel.y + y
                local paly = palettesel.y + (y % palettesel.h)
                for x = 0, (palettesel.w - 1) do
                    local mapx = mapsel.x + x
                    local palx = palettesel.x + (x % palettesel.w)
                    map:set_tile(layer, mapx, mapy, palx, paly)
                end
            end 
        end,
        set_flags = function(layer, isfirst)
            ctrl.pushundo(isfirst)

            for y = 0, (palettesel.h - 1) do
                local mapy = mapsel.y + y
                local paly = palettesel.y + (y % palettesel.h)
                for x = 0, (palettesel.w - 1) do
                    local mapx = mapsel.x + x
                    local palx = palettesel.x + (x % palettesel.w)
                    if clearingflags then
                        map:clear_flags(layer, mapx, mapy, flagmask)
                    else
                        map:set_flags(layer, mapx, mapy, flagmask)
                    end
                end
            end 
        end,
        set_tile_animation = function(period, count)
            return function()
                ctrl.pushundo(true)
                map:setTileAnimationInfo(editinglayer, mapsel.x, mapsel.y, period, count)               
            end
        end,
        moveview = function(dx, dy)
            return function()
                view.x = view.x + dx
                view.y = view.y + dy
            end
        end,
        setshift = function(b)
            return function()
                shift = b
            end
        end,
        setctrl = function(b)
            return function()
                ctrlkey = b
            end
        end,

        toggleflags = function()
            showflags = not showflags
        end,

        toggle_flag_in_mask = function(flag)
            return function() flagmask = flagmask ~ flag end
        end,

        undo = function()
            -- Seek back to the beginning of the most recent action and apply
            -- undo patches
            while true do
                local undoevent = undostack[#undostack]

                if undoevent then
                    map:patch(undoevent.data, undoevent)
                    undostack[#undostack] = nil

                    if undoevent.mark then
                        break
                    end
                else
                    break
                end
            end
        end,
        pushundo = function(marker)
            print('push undo')
            -- Get the selected area and push
            table.insert(undostack, {
                data = map:export{x=mapsel.x, y=mapsel.y, w=palettesel.w, h=palettesel.h},
                x = mapsel.x,
                y = mapsel.y,
                w = palettesel.w,
                h = palettesel.h,
                mark = marker
            })
        end,
    }
    
    --
    -- Views
    --
    local drawmap = function(tick, elapsed, counter)
        -- draw the map
        if showflags then
            map:draw_layer_flags(tileset, 0, view.x, view.y, view.w, view.h)
        else
            map:draw_layer(tileset, 0, view.x, view.y, view.w, view.h, counter)
        end

        -- draw selection rect
        local sx, sy = maptoscreen(mapsel.x, mapsel.y)
        engine:drawrect(sx - view.x, sy - view.y, mapsel.w * tileset.tw, mapsel.h * tileset.th)
        
        -- draw mouse-over rect
        engine:drawrect(mouserect.x, mouserect.y, mouserect.w, mouserect.h)
    end

    local drawpalette = function(tick, elapsed)
        -- draw the tiles
        tileset:drawwhole(0, 0)

        -- draw selection
        local sx, sy = palettesel.x * tileset.tw, palettesel.y * tileset.th
        engine:drawrect(sx, sy, palettesel.w * tileset.tw, palettesel.h * tileset.th)
        
        -- draw mouse-over
        engine:drawrect(mouserect.x, mouserect.y, mouserect.w, mouserect.h)
    end

    --
    -- Keyboard handlers
    --
    local onkey = {
        W = ctrl.moveview(0, -tileset.th),
        A = ctrl.moveview(-tileset.tw, 0),
        S = function()
            if ctrlkey then
                print('Saving...')
                if map:write(filename) then
                    print('Saved.')
                else
                    print('Saving failed!')
                end
            else 
                ctrl.moveview(0, tileset.th)()
            end
        end,
        D = ctrl.moveview(tileset.tw, 0),
        P = function()
            showtileset = not showtileset
            selecting = false
            if showtileset then
                engine:on{redraw=drawpalette}
            else
                engine:on{redraw=drawmap}
            end
        end,

        ['1'] = ctrl.set_tile_animation(1, nil),
        ['2'] = ctrl.set_tile_animation(2, nil),
        ['4'] = ctrl.set_tile_animation(4, nil),
        ['8'] = ctrl.set_tile_animation(8, nil),

        V = ctrl.set_tile_animation(nil, 1),
        B = ctrl.set_tile_animation(nil, 2),
        N = ctrl.set_tile_animation(nil, 4),
        M = ctrl.set_tile_animation(nil, 8),

        Z = function()
            if ctrlkey then
                ctrl.undo()
            end
        end,

        -- Flags
        F = ctrl.toggleflags,
        R = function()
            clearingflags = not clearingflags 
        end,

        L = ctrl.toggle_flag_in_mask(ant.tilemap.bumpeastflag),
        I = ctrl.toggle_flag_in_mask(ant.tilemap.bumpnorthflag),
        J = ctrl.toggle_flag_in_mask(ant.tilemap.bumpwestflag),
        K = ctrl.toggle_flag_in_mask(ant.tilemap.bumpsouthflag),

        ['Left Shift'] = ctrl.setshift(true),
        ['Right Shift'] = ctrl.setshift(true),

        ['Left Ctrl'] = ctrl.setctrl(true),
        ['Right Ctrl'] = ctrl.setctrl(true)

    }
    -- Default key handler
    setmetatable(onkey, {
        __index = function(tbl, key)
            return function() 
                print('unhandled key '..key)
            end
        end
    })
    

    --
    -- Install handlers and run
    engine:run{
        -- Default to drawing the map view
        redraw = drawmap, 

        keydown = function(key)
            -- Run keydown handlers defined above
            onkey[key]()
        end,

        keyup = function(key)
            -- Handle release of shift or control keys
            if key == 'Left Shift' or key == 'Right Shift' then
                shift = false
            elseif key == 'Left Ctrl' or key == 'Right Ctrl' then
                ctrlkey = false
            end
        end,

        mousebuttondown = function(x, y)
            selecting = true
            
            -- mark the corner of the selection, or draw tiles
            if showtileset then
                x = x // tileset.tw
                y = y // tileset.th
                palettesel.x = x
                palettesel.y = y
                palettesel.w = 1
                palettesel.h = 1
            else
                x, y = screentomap(x, y)
                mapsel.x = x
                mapsel.y = y
                if not shift then
                    mapsel.w = 1
                    mapsel.h = 1
                    if showflags then
                        ctrl.set_flags(editinglayer, true)
                    else
                        ctrl.set_tiles(editinglayer, true)
                    end
                end
            end 
        end,

        mousemotion = function(x, y)
            -- update mouse-over rectangle
            mouserect.x = x - (x % tileset.tw)
            mouserect.y = y - (y % tileset.th)

            -- Draw or update selection
            if selecting then
                if showtileset then
                    x = x // tileset.tw
                    y = y // tileset.th
                    
                    -- update palette selection
                    if shift then
                        palettesel.w, palettesel.h = x - palettesel.x + 1, y - palettesel.y + 1

                        -- make sure palette selection isn't reversed
                        if palettesel.w < 0 then
                            palettesel.x = palettesel.x + palettesel.w
                            palettesel.w = 0 - palettesel.w
                        end
                        if palettesel.h < 0 then
                            palettesel.y = palettesel.y + palettesel.h
                            palettesel.h = 0 - palettesel.h
                        end

                    else
                        palettesel.x, palettesel.y, palettesel.w, palettesel.h = x, y, 1, 1
                    end
                else
                    x, y = screentomap(x, y)
                    if shift then
                        -- update map selection
                        mapsel.w = x - mapsel.x + 1
                        mapsel.h = y - mapsel.y + 1

                        -- Make sure the selection isn't reversed
                        if mapsel.w < 0 then
                            mapsel.x = mapsel.x + mapsel.w
                            mapsel.w = 0 - mapsel.w
                        end
                        if mapsel.h < 0 then
                            mapsel.y  = mapsel.y + mapsel.h
                            mapsel.h = 0 - mapsel.h
                        end
                    else
                        mapsel.x, mapsel.y, mapsel.w, mapsel.h = x, y, 1, 1
                        if showflags then
                            ctrl.set_flags(editinglayer, true)
                        else
                            ctrl.set_tiles(editinglayer)
                        end
                    end
                end
            end
        end,


        mousebuttonup = function(ev)
            selecting = false
        end,


        quit = function()
            -- TODO prompt save
            print('quitting')
            engine:stop()
        end
    }
end


--
-- Create map and start editor
--

do
    local printusage = function(msg)
        print(msg)
        local usageprefix = arg[0]..' '..arg[1]..' '
        print('To edit an existing map: '..usageprefix..'<mapfile> <tileset>')
        print('To create a new map: '..usageprefix..'<mapfile> <tileset> <layers> <w> <h>')
    end

    -- Get arguments
    local mapfile = arg[2]
    local tilefile = arg[3]
    
    -- Map dimensions (if we're creating a new map)
    local layers = tonumber(arg[4])
    local w = tonumber(arg[5])
    local h = tonumber(arg[6])


    -- Build map creation options
    local mapoptions
    if layers and w and h then
        print(string.format('Creating map %s (%dx%dx%d)', mapfile, layers, w, h))
        mapoptions = {
            nlayers = layers,
            w = w,
            h = h
        }
    elseif mapfile then
        print('Opening map '..mapfile)
        mapoptions = {
            file = mapfile
        }
    end

    -- Try to create the map
    local map, err = Tilemap(mapoptions)
    if err then
        printusage("Couldn't load map: "..err)
        return
    end


    -- Run the editor
    editor(map, tilefile, mapfile)
end


