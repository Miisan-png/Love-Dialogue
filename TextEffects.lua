local TextEffects = {}

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

return TextEffects