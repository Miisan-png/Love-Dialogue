local LoveDialogue = require("LoveDialogue")
local ResourceManager = require("LoveDialogue.ResourceManager")
local PluginManager = require("LoveDialogue.PluginManager")  
local DebugPlugin = require("LoveDialogue.plugins.DebugPlugin")
local myDialogue
local savedState = nil

-- Use a variable for background color to demonstrate signal changes
local bgColor = {0.1, 0.1, 0.2, 1}

function love.load()
    love.window.setTitle("LoveDialogue Engine Demo")
    love.window.setMode(1024, 768, {resizable=true})
    love.graphics.setNewFont(16)
    
    -- Generate a synthetic blip sound
    local sampleRate = 44100
    local duration = 0.05
    local soundData = love.sound.newSoundData(math.floor(sampleRate * duration), sampleRate, 16, 1)
    for i = 0, soundData:getSampleCount() - 1 do
        local t = i / sampleRate
        local value = math.sin(t * 800 * math.pi * 2) * 0.5 -- 400Hz Sine wave
        soundData:setSample(i, value)
    end
    local blipSource = love.audio.newSource(soundData)
    
    -- Register the manual asset so LoveDialogue can find it by path string
    ResourceManager:registerManual(nil, "sound", "demo/assets/sfx/blip.wav", blipSource)
    
    PluginManager:register(DebugPlugin)
    
    local config = {
        boxHeight = 260,
        portraitEnabled = true,
        boxColor = {0.1, 0.1, 0.2, 0.95},
        textColor = {1, 1, 1, 1},
        nameColor = {1, 0.8, 0.2, 1},
        typingSpeed = 0.04,
        padding = 30,
        autoLayoutEnabled = true,
        skipKey = "f",
        character_type = 0,
        portraitSize = 260, 
        portraitFlipH = true,
        textSpeeds = { slow = 0.08, normal = 0.04, fast = 0.02 },
        initialSpeedSetting = "normal",
        autoAdvance = false,
        autoAdvanceDelay = 2.0,
        -- 9-Patch UI
        useNinePatch = true,
        ninePatchPath = "demo/assets/ui/9patch.png",
        ninePatchScale = 3,
        edgeWidth = 12,
        edgeHeight = 12,
        plugins = {"Debug"},
        pluginData = { Debug = { enabled = false } }
    }
    
    myDialogue = LoveDialogue.play("demo/demo.ld", config)
end

function love.update(dt)
    if myDialogue then myDialogue:update(dt) end
end

function love.draw()
    local w, h = love.graphics.getDimensions()
    for i = 0, h do
        love.graphics.setColor(0.1 + (i/h)*0.1, 0.1 + (i/h)*0.1, 0.2 + (i/h)*0.1, 1)
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
            print("Game Saved!", savedState.line, savedState.variables.coins)
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