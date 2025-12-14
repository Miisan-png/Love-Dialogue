local Transition = {}

local function easeInOutQuad(t)
    return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
end

function Transition.new()
    return {
        alpha = 0,
        color = {0, 0, 0},
        state = "idle",
        duration = 1,
        timer = 0,
        callback = nil
    }
end

function Transition.start(t, type, duration, color, callback)
    t.state = (type == "in") and "fading_in" or "fading_out"
    t.duration = duration or 1
    t.timer = 0
    t.callback = callback
    
    if color then
        t.color = color
    else
        t.color = {0, 0, 0} 
    end
    
    -- Fade Out: Transparent -> Opaque
    -- Fade In: Opaque -> Transparent
    if t.state == "fading_out" then t.alpha = 0 else t.alpha = 1 end
end

function Transition.update(t, dt)
    if t.state == "idle" then return end
    
    t.timer = t.timer + dt
    local progress = math.min(t.timer / t.duration, 1)
    local curve = easeInOutQuad(progress)
    
    if t.state == "fading_out" then
        t.alpha = curve
    else
        t.alpha = 1 - curve
    end
    
    if progress >= 1 then
        t.state = "idle"
        t.alpha = (t.state == "fading_out") and 1 or 0
        
        if t.callback then 
            local cb = t.callback
            t.callback = nil
            cb() 
        end
    end
end

function Transition.draw(t)
    if t.alpha <= 0 then return end
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(t.color[1], t.color[2], t.color[3], t.alpha)
    love.graphics.rectangle("fill", 0, 0, w, h)
end

return Transition