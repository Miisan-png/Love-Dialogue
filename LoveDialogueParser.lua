local Parser = {}

function Parser.parseFile(filePath)
    local lines = {}
    local characters = {}
    local currentLine = 1

    for line in love.filesystem.lines(filePath) do
        local character, text = line:match("^(%S+):%s*(.+)$")
        if character and text then
            local isEnd = text:match("%(end%)$")
            if isEnd then
                text = text:gsub("%s*%(end%)$", "")
            end

            local parsedLine = {character = character, text = "", isEnd = isEnd, effects = {}, branches = nil}
            local currentIndex = 1

            while true do
                local startTag, endTag, tag, content = text:find("{([^:}]+):([^}]*)}", currentIndex)

                if not startTag then
                    -- No more tags found, add the rest of the text
                    parsedLine.text = parsedLine.text .. text:sub(currentIndex)
                    break
                end

                -- Add text before the tag
                parsedLine.text = parsedLine.text .. text:sub(currentIndex, startTag - 1)

                local effect = {
                    type = tag,
                    content = content,
                    startIndex = #parsedLine.text + 1,
                    endIndex = #parsedLine.text + 1  -- This will be updated when we find the closing tag
                }

                -- Find the closing tag
                local closingStart, closingEnd = text:find("{/" .. tag .. "}", endTag + 1)
                if closingStart then
                    parsedLine.text = parsedLine.text .. text:sub(endTag + 1, closingStart - 1)
                    effect.endIndex = #parsedLine.text
                    currentIndex = closingEnd + 1
                else
                    -- If no closing tag, treat it as a single-character effect
                    parsedLine.text = parsedLine.text .. text:sub(endTag + 1, endTag + 1)
                    effect.endIndex = effect.startIndex
                    currentIndex = endTag + 2
                end

                table.insert(parsedLine.effects, effect)
            end

            lines[currentLine] = parsedLine

            if not characters[character] then
                characters[character] = {r = love.math.random(), g = love.math.random(), b = love.math.random()}
            end

            currentLine = currentLine + 1
        elseif line:match("^%[branch%d+%]") then
            local branchText = line:match("%[branch%d+%]%s*(.-)%s*%[/branch%d+%]")
            local targetLine = tonumber(line:match("%[target:(%d+)%]"))
            if branchText and targetLine then
                if not lines[currentLine - 1].branches then
                    lines[currentLine - 1].branches = {}
                end
                table.insert(lines[currentLine - 1].branches, {text = branchText, targetLine = targetLine})
            end
        end
    end

    return lines, characters
end

-- Debug function to print parsed information
function Parser.printDebugInfo(lines, characters)
    print("Parsed Lines:")
    for i, line in ipairs(lines) do
        print(string.format("Line %d:", i))
        print(string.format("  Character: %s", line.character))
        print(string.format("  Text: %s", line.text))
        print(string.format("  Is End: %s", tostring(line.isEnd)))

        print("  Effects:")
        for _, effect in ipairs(line.effects) do
            print(string.format("    Type: %s", effect.type))
            print(string.format("    Content: %s", effect.content))
            print(string.format("    Start Index: %d", effect.startIndex))
            print(string.format("    End Index: %d", effect.endIndex))
        end

        if line.branches then
            print("  Branches:")
            for _, branch in ipairs(line.branches) do
                print(string.format("    Target Line: %d", branch.targetLine))
                print(string.format("    Text: %s", branch.text))

                print("    Effects:")
                -- Branches do not include effects
            end
        end
    end

    print("Characters:")
    for character, color in pairs(characters) do
        print(string.format("  Character: %s", character))
        print(string.format("    Color: R=%f, G=%f, B=%f", color.r, color.g, color.b))
    end
end

return Parser
