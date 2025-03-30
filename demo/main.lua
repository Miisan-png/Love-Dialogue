-- demo/main.lua
local LoveDialogue = require("LoveDialogue")

local myDialogue

function love.load()
    -- Load the font if needed
    love.graphics.setNewFont(16)
    
    -- Configure the dialogue system
    local config = {
        boxHeight = 150,
        portraitEnabled = true,
        boxColor = {0.1, 0.1, 0.2, 0.9},
        textColor = {1, 1, 1, 1},
        nameColor = {1, 0.8, 0.2, 1},
        typingSpeed = 0.05,
        padding = 20,
        autoLayoutEnabled = true
    }
    
    -- Load the dialogue file from the demo folder
    myDialogue = LoveDialogue.play("demo/demo.ld", config)
    
    print("Dialogue loaded successfully!")
end

function love.update(dt)
    if myDialogue then
        myDialogue:update(dt)
    end
end

function love.draw()
    -- Background
    love.graphics.setColor(0.2, 0.2, 0.25, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Reset color before drawing dialogue
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw dialogue
    if myDialogue then
        myDialogue:draw()
    end
    
    -- Instructions
    love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
    love.graphics.print("Press SPACE/ENTER to advance dialogue", 10, 10)
    love.graphics.print("Press UP/DOWN to navigate choices", 10, 30)
    love.graphics.print("Press ESC to quit", 10, 50)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    
    if myDialogue then
        myDialogue:keypressed(key)
    end
end

function love.quit()
    if myDialogue then
        myDialogue:endDialogue()
    end
    
    print("Shutting down demo")
    return false
end