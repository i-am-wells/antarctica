

local running = true
while running do

    -- Loader

    local resource = nil
    engine:on{
        -- handlers here
        redraw = function()
            -- draw loading screen
            --
            if resource then
                engine:stop()
            end
        end,
        quit = function()
            -- quit handler
            running = false
        end
    }

    -- do asynchronous loading
    async([[
            -- loading task here
        ]],
        function(res)
            resource = res
        end
    )


    -- Main

    engine:on{
        -- main logic
    }

    engine:run()

end
