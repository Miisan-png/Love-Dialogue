local DebugPlugin = {
    name = "Debug",
    description = "Displays dialogue debug information",
    version = "1.0.2",
    author = "Miisan"
}

function DebugPlugin.init(d, data)
    data.enabled = true
    data.pos = {x = 10, y = 10}
    data.stats = { lines = 0, chars = 0, choices = 0, start = love.timer.getTime() }
end

function DebugPlugin.onCharacterTyped(d, data) data.stats.chars = data.stats.chars + 1 end
function DebugPlugin.onAfterAdvance(d, data) data.stats.lines = data.stats.lines + 1 end
function DebugPlugin.onChoiceSelected(d, data) data.stats.choices = data.stats.choices + 1 end

function DebugPlugin.handleKeyPress(d, data, key)
    if key == "f1" then
        data.enabled = not data.enabled
        return true
    end
    return false
end

function DebugPlugin.onAfterDraw(d, data)
    if not data.enabled then return end
    local r, g, b, a = love.graphics.getColor()
    
    local font = love.graphics.getFont()
    local lineHeight = font:getHeight() + 2
    local totalHeight = lineHeight * 9 -- 8 lines + padding
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", data.pos.x, data.pos.y, 240, totalHeight)
    
    love.graphics.setColor(0, 1, 0, 1)
    local y = data.pos.y + 5
    local function pr(t) love.graphics.print(t, data.pos.x + 5, y); y = y + lineHeight end
    
    pr("-- DEBUG --")
    pr("Line: " .. (d.state.currentLineIndex or 0))
    pr("Char: " .. (d.state.currentCharacter or "None"))
    pr("Lines Seen: " .. data.stats.lines)
    pr("Chars Typed: " .. data.stats.chars)
    pr("Choices: " .. data.stats.choices)
    pr("Time: " .. string.format("%.1fs", love.timer.getTime() - data.stats.start))
    pr("Res Count: " .. string.format("%.2f MB", collectgarbage("count")/1024))
    
    love.graphics.setColor(r, g, b, a)
end

function DebugPlugin.cleanup(d, data)
    print("Debug ended. Runtime: " .. string.format("%.1fs", love.timer.getTime() - data.stats.start))
end

return DebugPlugin