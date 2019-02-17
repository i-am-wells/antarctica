
-- for displaying frame rate
return function(engine, font, frametime, x, y)

    local fps = '∞'
    if frametime ~= 0 then
        fps = 1000 // frametime
    end

    engine:setColor(255,255,255,255)
    engine:fillRect(x, y, font.tw * 8, font.th)
    font:drawText(''..tostring(fps)..' fps', x, y, 200)
end

