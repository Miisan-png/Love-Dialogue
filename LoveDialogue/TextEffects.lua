local TextEffects = {}
local LD_PATH = (...):match('(.-)[^%.]+$')
local ResourceManager = require(LD_PATH .. "ResourceManager")

local activeSoundTags = {}

function TextEffects.color(effect, char, charIndex, timer)
    local r, g, b = effect.content:match("(%x%x)(%x%x)(%x%x)")
    if r and g and b then
        return {
            tonumber(r, 16)/255, 
            tonumber(g, 16)/255, 
            tonumber(b, 16)/255, 
            1
        }, {x = 0, y = 0, scale = 1}
    end
    return nil, {x = 0, y = 0, scale = 1}
end

function TextEffects.jiggle(effect, char, charIndex, timer)
    local intensity = tonumber(effect.content) or 1
    return nil, {
        x = math.random(-2, 2) * intensity,
        y = math.random(-2, 2) * intensity,
        scale = 1
    }
end

function TextEffects.wave(effect, char, charIndex, timer)
    local intensity = tonumber(effect.content) or 1
    return nil, {
        x = 0,
        y = math.sin((timer * 5) + (charIndex * 0.3)) * intensity * 3,
        scale = 1
    }
end

function TextEffects.shake(effect, char, charIndex, timer)
    local intensity = tonumber(effect.content) or 1
    local angle = love.math.random() * math.pi * 2
    return nil, {
        x = math.cos(angle) * intensity * 3,
        y = math.sin(angle) * intensity * 3,
        scale = 1
    }
end

function TextEffects.bold(effect, char, charIndex, timer)
    local intensity = tonumber(effect.content) or 2
    local offsets = {}

    for i = 1, intensity do
        local angle = (charIndex + i) * 0.5
        local x = math.cos(angle) * 1
        local y = math.sin(angle) * 1

        table.insert(offsets, {x = x, y = y})
    end

    return nil, {offsets = offsets}
end

function TextEffects.italic(effect, char, charIndex, timer)
    local shearDirection = -1 
    if effect.content == "left" then
        shearDirection = 1 -- Apply left lean
    end

    return nil, {shearX = 0.5 * shearDirection}
end

-- function TextEffects.sound(effect, char, charIndex, timer)
--     local filename = effect.content
--     local sound = ResourceManager.sounds[filename]
--     if sound and charIndex == effect.startIndex then
--         sound:play()
--     end
--     return nil, {x = 0, y = 0, scale = 1}
-- end



function TextEffects.sound(effect, char, charIndex, timer)
    -- 只在第一次遇到这个音效标签时播放
    if charIndex == effect.startIndex then
        -- 创建唯一标识符，包含音效文件和标签位置
        local soundTagID = string.format("%s_%d_%d", effect.content, effect.startIndex, effect.endIndex)
        
        -- 如果这个标签还没播放过
        if not activeSoundTags[soundTagID] then
            local sound = ResourceManager:get("sounds", effect.content)
            if sound then
                -- 停止之前可能还在播放的相同音效
                sound:stop()
                -- 播放音效
                sound:play()
                -- 标记这个标签为已播放
                activeSoundTags[soundTagID] = true
            end
        end
    end
    
    return nil, {x = 0, y = 0, scale = 1}
end

function TextEffects.resetSoundTags()
    activeSoundTags = {}
end

return TextEffects