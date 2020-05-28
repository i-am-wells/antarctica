local RawTile = require 'class'()

function RawTile:init(idx)
  self.idx = idx
end

function RawTile:getTileToDraw()
  return self.idx
end

function RawTile:setMapEditorContext(context)
  self.mapEditorContext = context
  self.model = context.model
  if __dbg then
    assert(context)
    assert(self.model)
  end
end

function RawTile:mouseDown(mapX, mapY, x, y, button)
  if __dbg then
    assert(self.mapEditorContext)
    assert(self.mapEditorContext.tileEditInProgress == nil)
  end
  local context = self.mapEditorContext
  context.tileEditInProgress = self.model:makeTileEdit()

  context.tileEditInProgress:addTile(context.editLayer, mapX, mapY,
    self:getTileToDraw())
end

function RawTile:mouseUp(mapX, mapY, x, y, button)
  if __dbg then
    assert(self.mapEditorContext)
  end

  if self.mapEditorContext.tileEditInProgress then
    self.model:update(self.mapEditorContext.tileEditInProgress)
    self.mapEditorContext.tileEditInProgress = nil
  end
end

function RawTile:mouseMotion(mapX, mapY, x, y, dx, dy)
  local context = self.mapEditorContext
  if __dbg then
    assert(context)
  end
  
  if context.tileEditInProgress then
    local mapX, mapY = context:screenToMap(x, y)
    if not context.tileEditInProgress:isSameLocationAsLast(context.editLayer, mapX, mapY) then
      context.tileEditInProgress:addTile(
        context.editLayer, mapX, mapY, self:getTileToDraw())
    end
  end
end

function RawTile:draw()
  if __dbg then
    assert(self.mapEditorContext)
  end

  local context = self.mapEditorContext
  -- Tile under cursor.
  context.engine:setColor(0, 255, 0, 255)
  local rectX, rectY = context:mapToScreen(context.mouseMapX, context.mouseMapY)
  context.engine:drawRect(rectX, rectY, context.tileset.tw, context.tileset.th)
end

return RawTile
