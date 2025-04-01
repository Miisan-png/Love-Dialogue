local LoveDialogue = require("LoveDialogue")
local myDialogue
local demoType = "standard" 

function love.load()
    love.graphics.setNewFont(16)
    
    local config = {
        boxHeight = 150,
        portraitEnabled = true,
        boxColor = {0.1, 0.1, 0.2, 0.9},
        textColor = {1, 1, 1, 1},
        nameColor = {1, 0.8, 0.2, 1},
        typingSpeed = 0.05,
        padding = 20,
        autoLayoutEnabled = true,
        skipKey = "f",
        textSpeeds = {
            slow = 0.08,
            normal = 0.05,
            fast = 0.02
        },
        initialSpeedSetting = "normal",
        autoAdvance = false,
        autoAdvanceDelay = 3.0,
        initialVariables = {
            playerName = "Player",
            health = 100,
            hasKey = false,
            meetingCount = 0
        }
    }
    local dialogueFile = demoType == "variable" and "demo/script_demo.ld" or "demo/demo.ld"
    myDialogue = LoveDialogue.play(dialogueFile, config)
    
    print("Dialogue loaded successfully!")
end

function love.update(dt)
    if myDialogue then
        myDialogue:update(dt)
    end
end

function love.draw()
    love.graphics.setColor(0.2, 0.2, 0.25, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setColor(1, 1, 1, 1)
    
    if myDialogue then
        myDialogue:draw()
    end
    
    love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
    love.graphics.print("Press SPACE/ENTER to advance dialogue", 10, 10)
    love.graphics.print("Press UP/DOWN to navigate choices", 10, 30)
    love.graphics.print("Press F to skip current text", 10, 50)
    love.graphics.print("Press T to cycle text speed", 10, 70)
    love.graphics.print("Press A to toggle auto-advance", 10, 90)
    love.graphics.print("Press V to switch to " .. (demoType == "standard" and "variable" or "standard") .. " demo", 10, 110)
    love.graphics.print("Press ESC to quit", 10, 130)
    love.graphics.setColor(1, 1, 0, 0.8)
    love.graphics.print("Current demo: " .. (demoType == "variable" and "Variable & Scripting" or "Standard"), 10, 160)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "v" then
        if myDialogue then
            myDialogue:endDialogue()
        end
        
        demoType = demoType == "standard" and "variable" or "standard"
        love.load() 
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