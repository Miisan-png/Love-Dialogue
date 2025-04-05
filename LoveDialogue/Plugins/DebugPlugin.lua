local DebugPlugin = {
    name = "Debug",
    description = "Displays dialogue debug information",
    version = "1.0.0",
    author = "Miisan"
}
function DebugPlugin.init(dialogue, pluginData)
    pluginData.enabled = true
    pluginData.position = {x = 470, y = 10}
    pluginData.stats = {
        lineCount = 0,
        charCount = 0,
        choicesMade = 0,
        startTime = love.timer.getTime()
    }
    print("DebugPlugin initialized!")
end

function DebugPlugin.onCharacterTyped(dialogue, pluginData, char, fullText)
    pluginData.stats.charCount = pluginData.stats.charCount + 1
end

function DebugPlugin.onAfterAdvance(dialogue, pluginData)
    pluginData.stats.lineCount = pluginData.stats.lineCount + 1
end

function DebugPlugin.onChoiceSelected(dialogue, pluginData, choiceIndex, choice)
    pluginData.stats.choicesMade = pluginData.stats.choicesMade + 1
end

function DebugPlugin.handleKeyPress(dialogue, pluginData, key)
    if key == "f1" then
        pluginData.enabled = not pluginData.enabled
        print("Debug display " .. (pluginData.enabled and "enabled" or "disabled"))
        return true 
    end
    return false
end

function DebugPlugin.onAfterDraw(dialogue, pluginData)
    if not pluginData.enabled then return end
    local r, g, b, a = love.graphics.getColor()
    local font = love.graphics.getFont()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", pluginData.position.x, pluginData.position.y, 200, 120)
    love.graphics.setColor(0, 1, 0, 1)
    local runtime = love.timer.getTime() - pluginData.stats.startTime
    local y = pluginData.position.y + 5
    love.graphics.print("-- DIALOGUE DEBUG --", pluginData.position.x + 5, y)
    y = y + 20
    love.graphics.print("Current line: " .. dialogue.currentLine, pluginData.position.x + 5, y)
    y = y + 15
    love.graphics.print("Character: " .. (dialogue.currentCharacter or "None"), pluginData.position.x + 5, y)
    y = y + 15
    love.graphics.print("Lines viewed: " .. pluginData.stats.lineCount, pluginData.position.x + 5, y)
    y = y + 15
    love.graphics.print("Characters typed: " .. pluginData.stats.charCount, pluginData.position.x + 5, y)
    y = y + 15
    love.graphics.print("Choices made: " .. pluginData.stats.choicesMade, pluginData.position.x + 5, y)
    y = y + 15
    love.graphics.print("Runtime: " .. string.format("%.1f", runtime) .. "s", pluginData.position.x + 5, y)
    love.graphics.setColor(r, g, b, a)
end
function DebugPlugin.cleanup(dialogue, pluginData)
    print("DebugPlugin cleaned up after " .. string.format("%.1f", 
        love.timer.getTime() - pluginData.stats.startTime) .. " seconds")
end

return DebugPlugin