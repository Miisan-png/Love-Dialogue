local LoveDialogue = require("LoveDialogue")
local ResourceManager = require("LoveDialogue.ResourceManager")
local PluginManager = require("LoveDialogue.PluginManager")  
local DebugPlugin = require("LoveDialogue.plugins.DebugPlugin")
local myDialogue
local savedState = nil
local config = nil
local nextScriptPath = nil

local bgColor = {0.1, 0.1, 0.2, 1}

local function onSignal(name, args)
    if name == "ChangeBG" then
        local r, g, b = args:match("(%S+)%s+(%S+)%s+(%S+)")
        if r and g and b then
            bgColor = {tonumber(r), tonumber(g), tonumber(b), 1}
        end
    elseif name == "LoadScript" then
        nextScriptPath = args
    elseif name == "QuitGame" then
        love.event.quit()
    elseif name == "PlaySound" then
         local s = love.audio.newSource(args, "static")
         s:play()
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("LoveDialogue Engine Demo")
    love.window.setMode(1024, 768, {resizable=true})
    love.graphics.setNewFont(16)
    
    PluginManager:register(DebugPlugin)
    
    config = {
        boxHeight = 220,
        boxWidth = 1200,
        centerBox = true,
        portraitEnabled = true,
        boxColor = {0, 0, 0, 1},
        borderColor = {1, 1, 1, 1},
        borderWidth = 4,
        textColor = {1, 1, 1, 1},
        nameColor = {1, 1, 1, 1},
        typingSpeed = 0.04,
        padding = 20,
        autoLayoutEnabled = true,
        skipKey = "f",
        character_type = 0,
        portraitSize = 140,
        portraitFlipH = true,
        textSpeeds = { slow = 0.08, normal = 0.04, fast = 0.02 },
        initialSpeedSetting = "normal",
        autoAdvance = false,
        autoAdvanceDelay = 2.0,
        useNinePatch = false,
        ninePatchPath = "demo/assets/ui/9patch.png",
        ninePatchScale = 1.5,
        edgeWidth = 12,
        edgeHeight = 12,
        indicatorPath = "demo/assets/ui/indicator.png",
        plugins = {"Debug"},
        pluginData = { Debug = { enabled = false } }
    }
    
    myDialogue = LoveDialogue.play("demo/launcher.ld", config)
    myDialogue.onSignal = onSignal
end

function love.update(dt)
    if nextScriptPath then
        if myDialogue then myDialogue:destroy() end
        myDialogue = LoveDialogue.play(nextScriptPath, config)
        myDialogue.onSignal = onSignal
        nextScriptPath = nil
        return
    end

    if myDialogue then myDialogue:update(dt) end
end

function love.draw()
    local w, h = love.graphics.getDimensions()
    for i = 0, h do
        local r = bgColor[1] + (i/h)*0.1
        local g = bgColor[2] + (i/h)*0.1
        local b = bgColor[3] + (i/h)*0.1
        love.graphics.setColor(r, g, b, 1)
        love.graphics.line(0, i, w, i)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    if myDialogue then myDialogue:draw() end
    
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print("Controls: Space/Enter (Next) | F (Skip) | S (Save) | L (Load)", 20, h - 30)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() 
    elseif key == "s" then
        if myDialogue then
            savedState = myDialogue:saveState()
            print("Game Saved!", savedState.line)
        end
    elseif key == "l" then
        if myDialogue and savedState then
            print("Loading Save...", savedState.line)
            myDialogue:loadState(savedState)
        end
    end
    
    if myDialogue then myDialogue:keypressed(key) end
end

function love.quit()
    if myDialogue then myDialogue:endDialogue() end
    ResourceManager:cleanup()
end