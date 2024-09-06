local Parser = {}

local function loadLuaFile(filePath)
    local chunk, err = loadfile(filePath)
    if not chunk then
        print("Error loading file:", err)
        return nil
    end
    return chunk()
end

local function parseTextWithTags(text)
    local parsedText = ""
    local effectsStack = {}
    local openEffects = {}
    local currentIndex = 1

    while currentIndex <= #text do
        local startTag, endTag, tag, content = text:find("{([^:}]+):([^}]*)}", currentIndex)
        local closingStartTag, closingEndTag, closingTag = text:find("{/([^}]+)}", currentIndex)

        if not startTag and not closingStartTag then
            -- No more tags found, add the rest of the text
            parsedText = parsedText .. text:sub(currentIndex)
            break
        end

        -- If we find a closing tag before an opening tag, we should handle it first
        if closingStartTag and (not startTag or closingStartTag < startTag) then
            -- Add text before the closing tag
            parsedText = parsedText .. text:sub(currentIndex, closingStartTag - 1)

            -- Close the most recent effect that matches the closing tag
            local effect
            for i = #openEffects, 1, -1 do
                if openEffects[i].type == closingTag then
                    effect = table.remove(openEffects, i)
                    break
                end
            end

            if effect then
                effect.endIndex = #parsedText
                table.insert(effectsStack, effect)
            end

            -- Move index past the closing tag
            currentIndex = closingEndTag + 1
        else
            -- Add text before the opening tag
            parsedText = parsedText .. text:sub(currentIndex, startTag - 1)

            -- Push the opening tag to the stack
            table.insert(openEffects, {type = tag, content = content, startIndex = #parsedText + 1})

            -- Move index past the opening tag
            currentIndex = endTag + 1
        end
    end

    -- Close any remaining open tags
    for _, effect in ipairs(openEffects) do
        effect.endIndex = #parsedText
        table.insert(effectsStack, effect)
    end

    return parsedText, effectsStack
end

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
            parsedLine.text, parsedLine.effects = parseTextWithTags(text)

            lines[currentLine] = parsedLine

            if not characters[character] then
                characters[character] = {r = love.math.random(), g = love.math.random(), b = love.math.random()}
            end

            currentLine = currentLine + 1
        elseif line:match("^%[branch%d+%]") then
            local branchText = line:match("%[branch%d+%]%s*(.-)%s*%[/branch%d+%]")
            local targetLine = tonumber(line:match("%[target:(%d+)%]"))
            local callbackFile = line:match("%?%s*([%w_%.]+)")

            if branchText and targetLine then
                local parsedBranchText, branchEffects = parseTextWithTags(branchText)

                if not lines[currentLine - 1].branches then
                    lines[currentLine - 1].branches = {}
                end

                -- Load the callback function if specified
                local callback
                if callbackFile then
                    -- Construct the path to the callback file
                    local callbackPath = love.filesystem.getRealDirectory(filePath) .. "/callbacks/" .. callbackFile
                    if callbackPath then
                        local loadedCallback = loadLuaFile(callbackPath)
                        if loadedCallback and type(loadedCallback.callback) == "function" then
                            callback = loadedCallback.callback
                        else
                            print("Callback function not found in file:", callbackFile)
                        end
                    else
                        print("Callback file does not exist:", callbackFile)
                    end
                end

                table.insert(lines[currentLine - 1].branches, {
                    text = parsedBranchText, 
                    effects = branchEffects,
                    targetLine = targetLine, 
                    callback = callback
                })
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
            for branchIndex, branch in ipairs(line.branches) do
                print(string.format("    Branch %d:", branchIndex))
                print(string.format("      Target Line: %d", branch.targetLine))
                print(string.format("      Text: %s", branch.text))

                -- Check and print branch effects
                if branch.effects then
                    print("      Effects:")
                    for _, effect in ipairs(branch.effects) do
                        print(string.format("        Type: %s", effect.type))
                        print(string.format("        Content: %s", effect.content))
                        print(string.format("        Start Index: %d", effect.startIndex))
                        print(string.format("        End Index: %d", effect.endIndex))
                    end
                else
                    print("      Effects: None")
                end

                -- Print branch callback
                if branch.callback then
                    print("    Callback: Loaded")
                else
                    print("    Callback: Not loaded")
                end
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
