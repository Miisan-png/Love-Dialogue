-- main.lua
local LoveDialogue = require "LoveDialogue"

local myDialogue

function love.load()
    myDialogue = LoveDialogue.play("exampleDialogue.ld", {
        enableFadeIn = true,
        enableFadeOut = true,
    })
end

function love.update(dt)
    if myDialogue then
        myDialogue:update(dt)
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Press SPACE to advance dialogue", 10, 10)
    
    if myDialogue then
        myDialogue:draw()
    end
end

function love.keypressed(key)
    if myDialogue then
        myDialogue:keypressed(key)
    end
end

