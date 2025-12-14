local LoveDialogue = require("LoveDialogue")
local ResourceManager = require("LoveDialogue.ResourceManager")
local PluginManager = require("LoveDialogue.PluginManager")  
local DebugPlugin = require("LoveDialogue.plugins.DebugPlugin")
local myDialogue

-- Use a variable for background color to demonstrate signal changes
local bgColor = {0.1, 0.1, 0.2, 1}

function love.load()
    love.window.setTitle("LoveDialogue Engine Demo")
    love.window.setMode(1024, 768, {resizable=true})
    love.graphics.setNewFont(16)
    
    PluginManager:register(DebugPlugin)
    
    local config = {
        -- 9-Patch UI
        useNinePatch = true,
        ninePatchPath = "demo/assets/ui/9patch.png",
        edgeWidth = 12,  -- Adjusted for standard 9-patch borders
        edgeHeight = 12,
        boxColor = {0.1, 0.1, 0.2, 0.95},
        textColor = {1, 1, 1, 1},
        nameColor = {1, 0.8, 0.2, 1},
        typingSpeed = 0.04,
        padding = 30,
        autoLayoutEnabled = true,
        skipKey = "f",
        character_type = 0,
        portraitSize = 260, 
        textSpeeds = { slow = 0.08, normal = 0.04, fast = 0.02 },
        initialSpeedSetting = "normal",
        autoAdvance = false,
        autoAdvanceDelay = 2.0,
        initialVariables = {
            -- Variables can be pre-seeded here if needed
            -- coins = 100
        },
        plugins = {"Debug"},
        pluginData = { Debug = { enabled = false } }
    }
    
    myDialogue = LoveDialogue.play("demo/demo.ld", config)
    
    -- Register a simple callback for signals
    myDialogue.onSignal = function(name, args)
        print("Signal Received:", name, args)
        if name == "ChangeBG" then
            local r, g, b = args:match("(%S+)%s+(%S+)%s+(%S+)")
            if r and g and b then
                bgColor = {tonumber(r), tonumber(g), tonumber(b), 1}
            end
        end
    end
end

function love.update(dt)
    if myDialogue then myDialogue:update(dt) end
end

function love.draw()
    local w, h = love.graphics.getDimensions()
    -- Background with dynamic color
    for i = 0, h do
        local r = bgColor[1] + (i/h)*0.1
        local g = bgColor[2] + (i/h)*0.1
        local b = bgColor[3] + (i/h)*0.1
        love.graphics.setColor(r, g, b, 1)
        love.graphics.line(0, i, w, i)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    if myDialogue then myDialogue:draw() end
    
    -- Clean UI
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print("Controls: Space/Enter (Next) | F (Skip) | F1 (Debug)", 20, h - 30)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if myDialogue then myDialogue:keypressed(key) end
end

function love.quit()
    if myDialogue then myDialogue:endDialogue() end
    ResourceManager:cleanup()
end