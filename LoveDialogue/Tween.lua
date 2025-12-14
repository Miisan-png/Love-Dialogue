local Tween = {}

local function lerp(a, b, t)
    return a + (b - a) * t
end

local easings = {
    linear = function(t) return t end,
    easeout = function(t) return 1 - (1 - t) * (1 - t) end,
    easein = function(t) return t * t end,
}

function Tween.new(target, keys, duration, easing, callback)
    local self = {
        target = target,
        keys = keys, 
        startValues = {},
        duration = duration or 1,
        timer = 0,
        easing = easings[easing] or easings.linear,
        callback = callback,
        finished = false
    }
    for k, v in pairs(keys) do
        self.startValues[k] = target[k] or 0
    end
    return self
end

function Tween.update(tween, dt)
    if tween.finished then return true end
    
    tween.timer = tween.timer + dt
    local t = math.min(tween.timer / tween.duration, 1)
    local factor = tween.easing(t)
    
    for k, endVal in pairs(tween.keys) do
        local startVal = tween.startValues[k]
        tween.target[k] = lerp(startVal, endVal, factor)
    end
    
    if t >= 1 then
        tween.finished = true
        if tween.callback then tween.callback() end
        return true 
    end
    return false
end

return Tween