local TextEffects = {}

function TextEffects.color(effect, char, charIndex, timer)
    local r, g, b = effect.content:match("#(%x%x)(%x%x)(%x%x)")
    if r and g and b then
        return {tonumber(r, 16)/255, tonumber(g, 16)/255, tonumber(b, 16)/255, 1}, {x = 0, y = 0}
    end
    return nil, {x = 0, y = 0}
end

function TextEffects.jiggle(effect, char, charIndex, timer)
    local intensity = tonumber(effect.content) or 1
    return nil, {
        x = love.math.random(-1, 1) * intensity,
        y = love.math.random(-1, 1) * intensity
    }
end

function TextEffects.wave(effect, char, charIndex, timer)
    local intensity = tonumber(effect.content) or 1
    return nil, {
        x = 0,
        y = math.sin(timer * 10 + charIndex * 0.5) * intensity * 2
    }
end

function TextEffects.shake(effect, char, charIndex, timer)
    local intensity = tonumber(effect.content) or 1
    local angle = love.math.random() * 2 * math.pi
    return nil, {
        x = math.cos(angle) * intensity,
        y = math.sin(angle) * intensity
    }
end

function TextEffects.rainbow(effect, char, charIndex, timer)
    local hue = (timer * 0.1 + charIndex * 0.1) % 1
    local r, g, b = HSVtoRGB(hue, 1, 1)
    return {r, g, b, 1}, {x = 0, y = 0}
end

-- Helper function to convert HSV to RGB
function HSVtoRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    return r, g, b
end

return TextEffects