local LoveDialogue = require "LoveDialogue"
--local DebugConsole = require "Debuging.DebugConsole"

local myDialogue

function love.load()
    --DebugConsole.init()

    -- Register callbacks with correct path
    local success, result = LoveDialogue.callbackHandler.registerFile("callbacks.lua")
    if not success then
        print("Failed to register callbacks:", result)
        return
    end
    print("Callbacks registered successfully!")

    local showSquareCallback = LoveDialogue.callbackHandler.getCallback("show_square")
    if showSquareCallback then
        print("DEBUG: show_square callback is available")
        -- Test the callback
        showSquareCallback()
        if _G.square and _G.square.visible then
            print("DEBUG: Callback executed successfully")
        end
    else
        print("DEBUG: show_square callback not found")
    end

    myDialogue = LoveDialogue.play("dialogue.ld", {
        boxHeight = 150,
        portraitEnabled = true
    })
    
end

function love.draw()
    -- Draw the square if it exists and is visible
    if _G.square and _G.square.visible then
        love.graphics.setColor(1, 0, 0, 1) -- Red square for visibility
        love.graphics.rectangle("fill", _G.square.x, _G.square.y, _G.square.size, _G.square.size)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end
    
    if myDialogue then
        myDialogue:draw()
    end
end

function love.update(dt)
    if myDialogue then
        myDialogue:update(dt)
    end
end

function love.keypressed(key)
    if myDialogue then
        myDialogue:keypressed(key)
    end
end