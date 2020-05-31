local RawTile = require 'class'()

function RawTile:init(arg)
  self.mapEditorContext = arg.mapEditor
  self.model = arg.mapEditor.model
  self.idx = arg.idx
  self.tileInfo = arg.tileInfo
end

function RawTile:getTileToDraw()
  return self.idx
end

function RawTile:mouseDown(mapX, mapY, x, y, button)
  if __dbg then
    assert(self.mapEditorContext)
    assert(self.mapEditorContext.tileEditInProgress == nil)
  end
  local context = self.mapEditorContext
  context.tileEditInProgress = self.model:makeTileEdit()

  self:addTile(mapX, mapY)
end

function RawTile:addTile(mapX, mapY)
  local context = self.mapEditorContext
  if self.tileInfo.eraseW and self.tileInfo.eraseH then
    for y = mapY, mapY + self.tileInfo.eraseH - 1 do
      for x = mapX, mapX + self.tileInfo.eraseW - 1 do
        context.tileEditInProgress:addTile(
          context.editLayer, x, y, --[[idx=]]0)
      end
    end
  end
  context.tileEditInProgress:addTile(context.editLayer, mapX, mapY, self.idx)
  context.map:synchronizeAnimation()
end

function RawTile:mouseUp(mapX, mapY, x, y, button)
  if __dbg then
    assert(self.mapEditorContext)
  end

  if self.mapEditorContext.tileEditInProgress then
    -- Commit edit
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
      self:addTile(mapX, mapY)
    end
  end
end

function RawTile:draw()
  if __dbg then
    assert(self.mapEditorContext)
  end

  local context = self.mapEditorContext
  local rectX, rectY = context:mapToScreen(context.mouseMapX, context.mouseMapY)
  local tileInfo = self.tileInfo

  -- Tile under cursor.
  if tileInfo.image then
    tileInfo.image:draw(
      tileInfo.sx,
      tileInfo.sy,
      tileInfo.w,
      tileInfo.h,
      rectX + tileInfo.dx,
      rectY + tileInfo.dy,
      tileInfo.w,
      tileInfo.h)
  end

  context.engine:setColor(0, 255, 0, 255)
  context.engine:drawRect(rectX, rectY, self.tileInfo.w, self.tileInfo.h)
end

return RawTile
