
local ant = require 'antarctica'
local Engine = require 'engine'
local Tilemap = require 'tilemap'
local Image = require 'image'

local CaveGen = require 'game.cavegen'

local drawTerrain = require 'maptools.drawterrain'
local makeShoreline = require 'maptools.makeshoreline'

local white = {r=255, g=255, b=255, a=255}

local editor = function(engine, tilemap, tileset, mapFilename, messageText)
    --local screenW, screenH = engine:getLogicalSize()
    local screenW, screenH = engine:getSize()
    local viewScale = 1
    print(screenW, screenH)

    local mapSelection = {l=0, x=0, y=0, w=1, h=1}
    local paletteSelection = {x=0, y=0, w=1, h=1}
    local mapSel0, paletteSel0 = {x=0, y=0}, {x=0, y=0}
    local eraserSelection = {x=16, y=0, w=1, h=1}
    
    local virtualScreenW, virtualScreenH = 480, 272

    local bgcolor = {r=0, g=0, b=0, a=255}
    local paletteBorderColor = {r=255, g=0, b=0, a=255}
    local setColor = function(color)
        engine:setColor(color.r, color.g, color.b, color.a)
    end


    local bgImage = Image{engine=engine, file='/home/ian/Pictures/bay.png'} --file='res/topomap.png'}
    local bgImageScaleX, bgImageScaleY = bgImage.w / tilemap.w, bgImage.h / tilemap.h

    local getPaletteRect = function()
        return {
            x=(screenW // 2) - (tileset.w / viewScale // 2) - 1, 
            y=(screenH // 2) - (tileset.h / viewScale // 2) - 1, 
            w=(tileset.w // viewScale + 2), 
            h=(tileset.h // viewScale + 2)
        }
    end
    local paletteRect = getPaletteRect()

    local drawRect = function(rect)
        engine:drawRect(rect.x, rect.y, rect.w, rect.h)
    end

    local infomsg = function(s)
        messageText = s
        print(s)
    end
    
    local font = Image{file = 'res/textbold-9x15.png', tilew=9, tileh=15, engine=engine}

    local editLayer = 0
    local layerMask = {}
    for l = 0, (tilemap.nlayers - 1) do
        layerMask[l] = true
    end
    local mapx, mapy = 0, 0
    local mouseX, mouseY = 0, 0

    local isCtrl = false
    local isSelectingMap, isSelectingPalette = false, false
    local isDrawingTiles = false
    local isFloodFillMode = false
    local showPalette, showFlags = false, false
    local isLive, needsRedraw = true, true
    local isCodeEntry = false

    local codeString = ''

    -- terrain drawing mode
    local isDrawingTerrain = false
    local terrainDir = 'e'
    local oldX, oldY = nil, nil

    local flagMask = 0

    local undoStack = {}
    local clipboard


    local animFramesIdx, animSpeedIdx = 0, 0
    local animSpeeds = {1, 2, 4, 8}
    local animFrames = {1, 2, 4, 8}


    local scaleXY = function(x, y)
        return (x / viewScale), (y / viewScale)
    end

    local screentomap = function(x, y)
        --x, y = scaleXY(x, y)
        return (mapx + x // (tileset.tw)), (mapy + y // (tileset.th))
    end
    local screentopalette = function(x, y)
        --x, y = scaleXY(x, y)
        return ((x - (paletteRect.x + 1)) // (tileset.tw / viewScale)), ((y - (paletteRect.y + 1)) // (tileset.th / viewScale))
    end

    local redraw = function()
        needsRedraw = true
    end

    local updateSelection = function(screenX, screenY, isPalette)
        local mx, my, selection, sel0
        if isPalette then
            mx, my = screentopalette(screenX, screenY)
            selection = paletteSelection
            sel0 = paletteSel0
        else
            mx, my = screentomap(screenX, screenY)
            selection = mapSelection
            sel0 = mapSel0
        end

        selection.x = math.min(mx, sel0.x)
        selection.w = math.max(mx, sel0.x) - selection.x + 1
        selection.y = math.min(my, sel0.y)
        selection.h = math.max(my, sel0.y) - selection.y + 1
    
        -- trim to boundaries
        selection.x = math.max(selection.x, 0)
        selection.y = math.max(selection.y, 0)
        if isPalette then
            selection.w = math.min(selection.w, (tileset.w // tileset.tw) - selection.x)
            selection.h = math.min(selection.h, (tileset.h // tileset.th) - selection.y)
        else
            selection.w = math.min(selection.w, tilemap.w - selection.x)
            selection.h = math.min(selection.h, tilemap.h - selection.y)
        end

        redraw()
    end

    local toggleLayer = function(layerNum)
        if (layerNum > -1) and (layerNum < tilemap.nlayers) then
            layerMask[layerNum] = not layerMask[layerNum]
            infomsg('Layer '..tostring(layerNum)..' visible: '..tostring(layerMask[layerNum]))
            redraw()
        end
    end

    local drawTextBox = function(text, x, y, w, h)
        -- draw info text
        setColor(white)
        engine:fillRect(x, y, w, h)
        font:drawText(text, x, y, w)
    end

    -- 
    -- Editing control routines
    --
    local edit
    edit = {
        replace = function(tx1, ty1)
            local tx0, ty0 = tilemap:getTile(editLayer, mapSelection.x, mapSelection.y)
            for y = 0, (tilemap.h - 1) do
                for x = 0, (tilemap.w - 1) do
                    local tx, ty = tilemap:getTile(editLayer, x, y)
                    if tx == tx0 and ty == ty0 then
                        tilemap:setTile(editLayer, x, y, tx1, ty1)
                    end
                end
            end

        end,
        sprinkle = function(prob)
            prob = prob or 0.125
            for y = 0, (tilemap.h - 1) do
                for x = 0, (tilemap.w - 1) do
                    
                end
            end
        end,
        floodFillTiles = function(centerX, centerY)
            -- flood fill using top left corner of palette selection
            local stack = {{centerX, centerY}}
            local origTx, origTy = tilemap:getTile(editLayer, centerX, centerY)

            -- stop right now if new tile is the same as original
            if (paletteSelection.x == origTx) and (paletteSelection.y == origTy) then
                return
            end

            local isFirst = true
            while #stack > 0 do
                -- pop
                local popped = stack[#stack]
                stack[#stack] = nil

                -- set tile
                local mapX, mapY = popped[1], popped[2]
                edit.pushUndo({x=mapX, y=mapY, w=1, h=1}, isFirst)
                isFirst = false
                tilemap:setTile(editLayer, mapX, mapY, paletteSelection.x, paletteSelection.y)

                -- push neighbors
                for _, p in ipairs{{1,0},{0,-1},{-1,0},{0,1}} do
                    local newX, newY = mapX + p[1], mapY + p[2]
                    local tx, ty = tilemap:getTile(editLayer, newX, newY)

                    -- is it the original "color"?
                    if (tx == origTx) and (ty == origTy) then
                        table.insert(stack, {newX, newY})
                    end
                end
            end
        end,

        changeAnimSpeed = function()
            animSpeedIdx = (animSpeedIdx + 1) % #animSpeeds

            for y = mapSelection.y, (mapSelection.y + mapSelection.h - 1) do
                for x = mapSelection.x, (mapSelection.x + mapSelection.w - 1) do
                    tilemap:setTileAnimationInfo(editLayer, x, y, animSpeeds[animSpeedIdx + 1], nil)
                end
            end
        end,
        
        changeAnimFrames = function()
            animFramesIdx = (animFramesIdx + 1) % #animFrames

            for y = mapSelection.y, (mapSelection.y + mapSelection.h - 1) do
                for x = mapSelection.x, (mapSelection.x + mapSelection.w - 1) do
                    tilemap:setTileAnimationInfo(editLayer, x, y, nil, animFrames[animFramesIdx + 1])
                end
            end
        end,

        drawTilesFromPalette = function(isFirst, optX, optY)
            -- Draw one patch (paletteSelection) to the corner of map selection
            local mapX, mapY = optX or mapSelection.x, optY or mapSelection.y
            local boundX = math.min(paletteSelection.w, tilemap.w - mapX) - 1
            local boundY = math.min(paletteSelection.h, tilemap.h - mapY) - 1
            local layer = editLayer

            if mapX < 0 or mapX >= tilemap.w or mapY < 0 or mapY >= tilemap.h then
                return
            end

            edit.pushUndo(
                {x=mapX, y=mapY, w=(boundX+1), h=(boundY+1)}, 
                isFirst
            )
            -- map and tiles are zero-indexed
            for y = 0, boundY do
                for x = 0, boundX do
                    tilemap:setTile(
                        layer, 
                        mapX + x, 
                        mapY + y, 
                        paletteSelection.x + x, 
                        paletteSelection.y + y
                    )
                end
            end

            redraw()
        end,
        drawTerrain = function(oldX, oldY, mapx, mapy)
            
            -- check if it's a valid move and get the direction
            local newDir = drawTerrain.getMoveDirection(oldX, oldY, mapx, mapy, terrainDir)
            if newDir then
                drawTerrain.drawTerrain(tilemap, terrainDir, newDir, oldX, oldY, mapx, mapy, true)
                terrainDir = newDir
            end
        end,
        drawBumpFlagsToggle = function(isFirst, optX, optY)
            local layer = editLayer
            local mapX, mapY = optX or mapSelection.x, optY or mapSelection.y

            edit.pushUndo(mapSelection, isFirst)

            -- map and tiles are zero-indexed
            for y = 0, mapSelection.h - 1 do
                for x = 0, mapSelection.w - 1 do
                    tilemap:overwriteFlags(
                        layer, 
                        mapX + x, 
                        mapY + y, 
                        flagMask
                    )
                end
            end

            redraw()
            
        end,
        undo = function()
            -- Seek back to the beginning of the most recent action and apply
            -- undo patches
            while true do
                local undoevent = undoStack[#undoStack]

                if undoevent then
                    tilemap:patch(undoevent.data, undoevent)
                    undoStack[#undoStack] = nil

                    if undoevent.mark then
                        break
                    end
                else
                    break
                end
            end
        end,
        pushUndo = function(rect, marker)
            -- Get the selected area and push
            rect.data = tilemap:export(rect)
            rect.mark = marker
            table.insert(undoStack, rect)
        end,
        copy = function()
            infomsg('Copied.')
            -- copy map selection to clipboard
            clipboard = {}
            for k,v in pairs(mapSelection) do clipboard[k] = v end
            clipboard.data = tilemap:export(clipboard)
        end,
        paste = function()
            infomsg('Pasted.')
            if clipboard then
                clipboard.x = mouseX
                clipboard.y = mouseY
                edit.pushUndo(clipboard, true)
                tilemap:patch(clipboard.data, clipboard)
            end
        end,
    }

    local stepSize = function()
        if viewScale < 1 then
            return 1 / viewScale
        else
            return 1
        end
    end

    -- 
    -- Key down handlers
    --
    local keyboardHandlers = setmetatable(
        {
            Right = function() 
                if isDrawingTerrain then
                    terrainDir = 'e'
                    infomsg('Terrain drawing direction: '..terrainDir)
                end
            end,
            Up = function() 
                if isDrawingTerrain then
                    terrainDir = 'n'
                    infomsg('Terrain drawing direction: '..terrainDir)
                end
            
            end,
            Left = function() 
                if isDrawingTerrain then
                    terrainDir = 'w'
                    infomsg('Terrain drawing direction: '..terrainDir)
                end
            
            end,
            Down = function() 
                if isDrawingTerrain then
                    terrainDir = 's'
                    infomsg('Terrain drawing direction: '..terrainDir)
                end
            
            end,
            ['['] = function()
                editLayer = (editLayer - 1) % tilemap.nlayers
                infomsg('Switched to layer '..tostring(editLayer))
            end,
            [']'] = function()
                editLayer = (editLayer + 1) % tilemap.nlayers
                infomsg('Switched to layer '..tostring(editLayer))
            end,
            A = function()
                if showPalette then
                    paletteSelection.x = math.max(paletteSelection.x - 1, 0)
                else
                    mapx = mapx - stepSize()
                end
                redraw()
            end,
            C = function()
                if isCtrl then
                    edit.copy()
                end
            end,
            D = function()
                if showPalette then
                    paletteSelection.x = paletteSelection.x + 1
                else
                    mapx = mapx + stepSize()
                end
                redraw()
            end,
            E = function()
                local tmp = paletteSelection
                paletteSelection = eraserSelection
                eraserSelection = tmp
                infomsg('Toggled eraser mode.')
            end,
            F = function()
                isFloodFillMode = not isFloodFillMode
                infomsg('Flood fill: '..tostring(isFloodFillMode))
                redraw()
            end,
            G = function()
                showFlags = not showFlags
                infomsg('Flags shown: '..tostring(showFlags))
                redraw()
            end,
            H = function()
                flagMask = flagMask ~ ant.tilemap.bumpwestflag
            end,
            J = function()
                flagMask = flagMask ~ ant.tilemap.bumpsouthflag
            end,
            K = function()
                flagMask = flagMask ~ ant.tilemap.bumpeastflag
            end,
            L = function()
                isLive = not isLive
                redraw()
            end,
            M = function()
                if isCtrl then
                    -- TODO better way to select legend
                    infomsg('Making terrain')
                    local mapSelection = {x=0, y=0, w=tilemap.w, h=tilemap.h}
                    makeShoreline.convert(tilemap, editLayer, makeShoreline.terrainLegend, mapSelection)
                    infomsg('Made terrain')
                    redraw()
                end
            end,

            O = function()
                infomsg('Changed animation frame count for selection')
                edit.changeAnimFrames()
            end,
            P = function()
                infomsg('Changed animation speed for selection')
                edit.changeAnimSpeed()
            end,

            R = function()
                if isCtrl then
                    edit.replace(paletteSelection.x, paletteSelection.y)
                    infomsg('Did replace.')
                    redraw()
                end
            end,
            S = function()
                if isCtrl then
                    infomsg('Saving to '..mapFilename..'...')
                    if tilemap:write(mapFilename) then
                        infomsg('Saved.')
                    else
                        infomsg('Failed!')
                    end
                else
                    if showPalette then
                        paletteSelection.y = paletteSelection.y + 1
                    else
                        mapy = mapy + stepSize()
                    end
                    redraw()
                end
            end,

            T = function()
                isDrawingTerrain = not isDrawingTerrain
                infomsg('Terrain drawing mode: '..tostring(isDrawingTerrain))
            end,
            U = function()
                flagMask = flagMask ~ ant.tilemap.bumpnorthflag
            end,
            V = function()
                if isCtrl then
                    edit.paste()
                end
            end,
            W = function()
                if showPalette then
                    paletteSelection.y = math.max(paletteSelection.y - 1, 0)
                else
                    mapy = mapy - stepSize()
                end
                redraw()
            end,
            Z = function()
                if isCtrl then
                    edit.undo()
                end
            end,
            ['Left Shift'] = function()
                showPalette = true
            end,
            ['Left Ctrl'] = function()
                isCtrl = true
            end,
            Escape = function()
                if isCodeEntry then
                    isCodeEntry = false
                    ant.engine.stopTextInput()
                else
                    ant.engine.startTextInput()
                    codeString = ''
                    isCodeEntry = true
                end
            end
        }, {__index = function(tbl, key) 
            local layerNum = tonumber(key)
            if layerNum ~= nil then
                return function() toggleLayer(layerNum) end
            end
                
            return function() print('unhandled key '..key) end 
        end}
    )


    engine:run{
        redraw = function(tick, frametime, counter)

            if (not isLive) and (not needsRedraw) then
                return
            end

            -- clear
            setColor(bgcolor)
            engine:clear()

            -- TODO temporary: draw background image
            if bgImage then
                bgImage:draw(
                    0, 0, bgImage.w, bgImage.h,
                    -mapx * tileset.tw,
                    -mapy * tileset.th,
                    bgImage.w * tileset.tw // bgImageScaleX,
                    bgImage.h * tileset.th // bgImageScaleY
                )
            end

            -- draw map
            for l = 0, tilemap.nlayers - 1 do
                if layerMask[l] then
                    if showFlags then
                        tilemap:drawLayerFlags(tileset, l, mapx * tileset.tw, mapy * tileset.th, screenW, screenH)
                    else
                        tilemap:drawLayer(tileset, l, mapx * tileset.tw, mapy * tileset.th, screenW, screenH, counter)
                    end
                end
            end

            -- terrain editing?
            if isDrawingTerrain and oldX then
                -- draw green squares on valid next choices
                --
                -- TODO
                engine:setColor(0, 255, 0, 255)
                for _, dir in ipairs(drawTerrain.validNextDirections(terrainDir)) do
                    local v = drawTerrain.directions[dir]
                    local cx, cy = oldX+v.x, oldY+v.y

                    while (cx > mapx) and (cy > mapy) and (cx <= (mapx + (screenW) // tileset.tw)) and (cy <= (mapy + (screenH) // tileset.th)) do
                        
                        --print(cx,cy)
                        if cx ~= mouseX or cy ~= mouseY then
                            engine:fillRect(
                                (cx - mapx) * tileset.tw,
                                (cy - mapy) * tileset.th,
                                tileset.tw,
                                tileset.th
                            )
                        end
                        
                        cx = cx + v.x
                        cy = cy + v.y
                    end
                end
            end

            -- draw map selection
            setColor(bgcolor)
            engine:drawRect(
                (mapSelection.x - mapx) * tileset.tw,
                (mapSelection.y - mapy) * tileset.th,
                mapSelection.w * tileset.tw,
                mapSelection.h * tileset.th
            )

            if showPalette then
                -- draw palette border
                engine:setColor(255, 0, 255, 255)
                engine:fillRect(paletteRect.x, paletteRect.y, paletteRect.w, paletteRect.h)
                setColor(paletteBorderColor)
                drawRect(paletteRect)

                -- draw palette
                --[[
                for paly = 0, (tileset.h // tileset.th) - 1 do
                    for palx = 0, (tileset.w // tileset.tw) - 1 do
                        tileset:drawTile(
                            palx, paly, 
                            paletteRect.x + (palx*tileset.tw) + 1,
                            paletteRect.y + (paly*tileset.th) + 1
                        )
                    end
                end
                ]]--
                tileset:draw(
                    0, 0, tileset.w, tileset.h,
                    paletteRect.x + 1, paletteRect.y + 1, paletteRect.w - 2, paletteRect.h - 2
                )
                
                
                -- draw palette selection
                engine:drawRect(
                    paletteRect.x + paletteSelection.x * tileset.tw // viewScale + 1,
                    paletteRect.y + paletteSelection.y * tileset.th // viewScale + 1,
                    paletteSelection.w * tileset.tw // viewScale,
                    paletteSelection.h * tileset.th // viewScale
                )
            else
                -- draw mouseover box
                setColor(bgcolor)
                engine:drawRect(
                    (mouseX - mapx) * tileset.tw,
                    (mouseY - mapy) * tileset.th,
                    tileset.tw, tileset.th
                )

                -- draw view box
                engine:setColor(0, 255, 0, 255)
                engine:drawRect(
                    (mouseX - mapx) * tileset.tw - (virtualScreenW  * viewScale // 2),
                    (mouseY - mapy) * tileset.th - (virtualScreenH * viewScale // 2),
                    virtualScreenW * viewScale // 1,
                    virtualScreenH * viewScale // 1
                )
            end


            local infoText = string.format(
                    '%d, %d (selection: layer %d - %d, %d, %dx%d), %dfps, %fx', 
                    mouseX, mouseY, editLayer,
                    mapSelection.x, mapSelection.y, mapSelection.w, mapSelection.h,
                    1000 // math.max(frametime, 16), viewScale
                )
            drawTextBox(infoText, 0, screenH - 15, screenW, 15)
            drawTextBox(messageText, screenW // 2, screenH - 15, screenW // 2, 15)
            
            if isCodeEntry then
                engine:setColor(255, 255, 255, 255)
                engine:fillRect(screenW / 2, 0, screenW / 2, screenH / 2)
                drawTextBox(codeString, screenW / 2, 0, screenW / 2, screenH / 2)
            end


            needsRedraw = false
        end,

        keydown = function(key)
            --print(key)
            if isCodeEntry then
                -- on ctrl+enter, try to run the given code
                if key == 'Return' and isCtrl then
                    local fn, err = load(codeString)
                    if not fn then
                        infomsg(err)
                    else
                        -- run
                        fn()
                        codeString = ''
                    end
                elseif key == 'Escape' or key == 'Left Ctrl' then
                    keyboardHandlers[key]()
                end
            else
                keyboardHandlers[key]()
            end
        end,

        keyup = function(key)
            if key == 'Left Shift' then
                showPalette = false
                isSelectingPalette = false
            elseif key == 'Left Ctrl' then
                isCtrl = false
            end
        end,

        
        textinput = function(text)
            codeString = codeString..text    
        end,
        

        mousebuttondown = function(x, y, button)
            if button == ant.engine.mousebuttonleft then
                if showPalette then
                    -- single-select from palette
                    local palx, paly = screentopalette(x, y)
                    paletteSel0 = {x=palx, y=paly}
                    paletteSelection = {x=palx, y=paly, w=1, h=1}
                else
                    -- draw on map
                    local mapX, mapY = screentomap(x, y)
                    
                    -- draw from palette
                    if showFlags then
                        edit.drawBumpFlagsToggle(true)
                    else
                        if isDrawingTerrain then
                            if oldX ~= nil then
                                edit.drawTerrain(oldX, oldY, mapX, mapY)
                            end
                            oldX, oldY = mapX, mapY
                        elseif isFloodFillMode then
                            edit.floodFillTiles(mapX, mapY)
                            isFloodFillMode = false
                            infomsg('Flood fill mode: false')
                        else
                            edit.drawTilesFromPalette(true, mapX, mapY)
                            isDrawingTiles = true
                        end
                    end
                    
                end
            elseif button == ant.engine.mousebuttonright then
                if showPalette then
                    -- rectangle-select from palette
                    local palx, paly = screentopalette(x, y)
                    paletteSel0 = {x=palx, y=paly}
                    paletteSelection = {x=palx, y=paly, w=1, h=1}
                    isSelectingPalette = true
                else
                    -- rectangle-select from map
                    -- set map selection
                    local mapx, mapy = screentomap(x, y)
                    mapSel0 = {x=mapx, y=mapy}
                    mapSelection = {x=mapx, y=mapy, w=1, h=1}
                    isSelectingMap = true
                end
            end
        end,

        mousebuttonup = function(x, y, button)
            if button == ant.engine.mousebuttonleft then
                if isDrawingTiles then
                    isDrawingTiles = false
                end
            elseif button == ant.engine.mousebuttonright then
                if showPalette and isSelectingPalette then
                    isSelectingPalette = false
                    updateSelection(x, y, true)
                elseif isSelectingMap then
                    isSelectingMap = false
                    updateSelection(x, y)
                end
            end
        end,
        
        mousemotion = function(x, y)
            -- update mouseX and mouseY for displaying location in status text
            mouseX, mouseY = screentomap(x, y)
            redraw()

            -- update selection
            if isSelectingPalette then
                updateSelection(x, y, true)
            elseif isSelectingMap then
                updateSelection(x, y)
            elseif isDrawingTiles then
                edit.drawTilesFromPalette(false, mouseX, mouseY)
            end
        end,

        mousewheel = function(x, y)
            if y > 0 then
                viewScale = viewScale * 2
            elseif y < 0 then
                viewScale = viewScale * 0.5
            end
            if viewScale < 0.125 then
                viewScale = 0.125
            end
            tileset:scale(viewScale)
            screenW, screenH = engine:getSize()
            paletteRect = getPaletteRect()

            -- Center on mouse


            redraw()
        end,

        quit = function()
            print('quitting...')
            engine:stop()
        end
    }
end

do
    -- get arguments
    local printUsage = function(msg)
        print(msg)
        local usageprefix = arg[0]..' '..arg[1]..' '
        print('To edit an existing map: '..usageprefix..'<mapfile> <tileset>')
        print('To create a new map: '..usageprefix..'<mapfile> <tileset> <layers> <w> <h>')
    end

    -- next two should always be present
    local mapFilename, tilesetFilename = arg[2], arg[3]
    if not (mapFilename and tilesetFilename) then
        return printUsage('Please provide a map file and tileset')
    end

    -- dimensions (for creating new map)
    local numLayers, w, h = tonumber(arg[4]), tonumber(arg[5]), tonumber(arg[6])
   
    local tilemap
    if numLayers and w and h then
        if arg[7] == 'cavegen' then
            local cavegen = CaveGen{
                w = w,
                h = h,
                nlayers = numLayers,
                count = 300
            }

            tilemap = cavegen:generate()

        else
            tilemap, err = Tilemap{nlayers = numLayers, w = w, h = h}
            if tilemap and numLayers > 1 then
                --tilemap:clean(16,0)
            end
        end
    else
        tilemap, err = Tilemap{file = mapFilename}
    end

    if err then
        return print('Failed to create/open map: '..err)
    end

    -- Create window etc.
    local engine, err = Engine{
        title = 'map editor',
        --w=400, h=300, --windowflags = ant.engine.fullscreen,
        windowflags = ant.engine.fullscreendesktop,
        rendererflags = ant.engine.rendervsync | ant.engine.renderaccelerated | ant.engine.rendertargettexture,
        targetfps = 30
    }
    if err then
        return print('Failed to create window: '..err)
    end


    --engine:setScale(2, 2)

    

    -- Load tileset
    local tileset, err = Image{file = tilesetFilename, engine = engine}
    if err then
        return print('Failed to load tileset: '..err)
    end


    --print(tilemap:prerenderLayer(0, tileset))

    local messageText = 'Opened '..mapFilename..'.'

    -- Run editor
    editor(engine, tilemap, tileset, mapFilename, messageText)
end

