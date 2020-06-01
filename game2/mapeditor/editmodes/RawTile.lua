local Stack = require 'Stack'
local EditMode = require 'game2.mapeditor.editmodes.EditMode'
local RawTile = require 'class'(EditMode)

function RawTile:init(arg)
  EditMode.init(self, arg)
  self.idx = arg.idx
  self.tileInfo = arg.tileInfo
end

function RawTile:getIdx(mapX, mapY)
  return self.mapEditorContext.map:getTileInfoIdxForTile(
    self.mapEditorContext.editLayer, mapX, mapY)
end

function RawTile:startEdit()
  self.mapEditorContext.tileEditInProgress = self.model:makeTileEdit()
end

function RawTile:commitEdit()
  if self.mapEditorContext.tileEditInProgress then
    self.model:update(self.mapEditorContext.tileEditInProgress)
    self.mapEditorContext.tileEditInProgress = nil
  end
  self.mapEditorContext.map:synchronizeAnimation()
end

function RawTile:mouseDown(mapX, mapY, x, y, button)
  if self.isFloodFill then
    self:floodFill(mapX, mapY)
    return
  end

  if __dbg then
    assert(self.mapEditorContext)
    assert(self.mapEditorContext.tileEditInProgress == nil)
  end
  self:startEdit()
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
end

function RawTile:floodFill(mapX, mapY)
  self:startEdit()
  local toReplace = self:getIdx(mapX, mapY)
  local eraseW, eraseH = self.tileInfo.eraseW or 1, self.tileInfo.eraseH or 1
  local stack = Stack()
  stack:push{x=mapX, y=mapY}
  while not stack:empty() do
    local p = stack:pop()
    if self:getIdx(p.x, p.y) == toReplace then
      self:addTile(p.x, p.y)

      if (p.x - eraseW) >= 0 then
        stack:push{x=p.x-eraseW, y=p.y}
      end
      if (p.x + eraseW) < self.mapEditorContext.map.w then
        stack:push{x=p.x+eraseW, y=p.y}
      end
      if (p.y - eraseH) >= 0 then
        stack:push{x=p.x, y=p.y-eraseH}
      end
      if (p.y + eraseH) < self.mapEditorContext.map.h then
        stack:push{x=p.x, y=p.y+eraseH}
      end
    end
  end
  self:commitEdit()
end

function RawTile:mouseUp(mapX, mapY, x, y, button)
  if __dbg then
    assert(self.mapEditorContext)
  end

  self:commitEdit()
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
