local Parser = {}
local LD_PATH = (...):match('(.-)[^%.]+$')
local PortraitManager = require(LD_PATH .. "PortraitManager")
local LD_Character = require(LD_PATH .. "LoveCharacter")
local CharacterParser = require(LD_PATH .. "LoveCharacterParser")

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
    local effectsTable = {}
    local openEffects = {}
    local currentIndex = 1

    while currentIndex <= #text do
        local startTag, endTag, tag, content = text:find("{([^:}]+):([^}]*)}", currentIndex)
        local closingStartTag, closingEndTag, closingTag = text:find("{/([^}]+)}", currentIndex)

        if not startTag and not closingStartTag then
            parsedText = parsedText .. text:sub(currentIndex)
            break
        end

        if closingStartTag and (not startTag or closingStartTag < startTag) then
            parsedText = parsedText .. text:sub(currentIndex, closingStartTag - 1)

            local effect
            for i = #openEffects, 1, -1 do
                if openEffects[i].type == closingTag then
                    effect = table.remove(openEffects, i)
                    break
                end
            end

            if effect then
                effect.endIndex = #parsedText
                table.insert(effectsTable, effect)
            end

            currentIndex = closingEndTag + 1
        else
            parsedText = parsedText .. text:sub(currentIndex, startTag - 1)

            table.insert(openEffects, {type = tag, content = content, startIndex = #parsedText + 1})

            currentIndex = endTag + 1
        end
    end

    for _, effect in ipairs(openEffects) do
        effect.endIndex = #parsedText
        table.insert(effectsTable, effect)
    end

    return parsedText, effectsTable
end

Parser.parseTextWithTags = parseTextWithTags

--- Parses a dialogue file and returns a table of lines
--- @param filePath string
--- @return string[]
--- @return table<string, LD_Character>
--- @return table
function Parser.parseFile(filePath)
    local lines = {}
    local currentLine = 1
    local scenes = {}
    local currentScene = "default"
    local characters = {}
    
    -- Read file content
    local fileContent = love.filesystem.read(filePath)
    if not fileContent then
        error("Could not read file: " .. filePath)
        return
    end
    
    -- First pass: Handle portrait definitions
    for line in fileContent:gmatch("[^\r\n]+") do
        local characterName, path = line:match("^@portrait%s+(%S+)%s+(.+)$")
        if characterName and path then
            local character, error = CharacterParser.parseCharacterFromPortrait(characterName, path)
            
            if error or character == nil then
                print("Error parsing character file:", error)
            end
            
            characters[characterName] = character
            PortraitManager.loadPortrait(character, path:match("^%s*(.-)%s*$"))
        end
        
        local characterPath = line:match("@Character%s+([^#%s]+)")
        if characterPath then
            local character, error = CharacterParser.parseCharacter(characterPath)

            if error or character == nil then
                print("Error parsing character file:", error)
            else
                for _, c in ipairs(character) do
                    characters[c.name] = c
                end
            end
        end
    end
    
    local fileLines = {}
    for line in fileContent:gmatch("[^\r\n]+") do
        if not line:match("^@callback") then
            table.insert(fileLines, line)
        end
    end

    for _, line in ipairs(fileLines) do
        local character, text = line:match("^(%S+):%s*(.+)$")
        if character and text then
            local characterName = character:gsub("%(.*%)$", "")
            local expression = character:match("%((.-)%)")
            if not characters[characterName] then
                characters[characterName] = LD_Character.new(characterName)
            end

            local isEnd = text:match("%(end%)$")
            if isEnd then
                text = text:gsub("%s*%(end%)$", "")
            end

            local parsedText, effects = Parser.parseTextWithTags(text)
            local parsedLine = {
                character = characterName,
                expression = expression or "Default",
                text = parsedText,
                isEnd = isEnd,
                effects = effects,
                choices = {}
            }

            lines[currentLine] = parsedLine
            currentLine = currentLine + 1
        elseif line:match("^%->") then
            print("DEBUG: Processing choice line:", line)
            line = line:gsub("[\r\n]", "")
            
            local choiceText, target = line:match("^%->%s*([^%[]+)%s*%[target:([%w_]+)%]%s*$")
            
            print("DEBUG: Raw matches:")
            print("  Text:", choiceText and '"'..choiceText..'"' or "nil")
            print("  Target:", target and '"'..target..'"' or "nil")
            
            if choiceText then
                -- Trim whitespace
                choiceText = choiceText:match("^%s*(.-)%s*$")
                target = target and target:match("^%s*(.-)%s*$")
                
                print("DEBUG: After trimming:")
                print("  Text:", '"'..choiceText..'"')
                print("  Target:", target and '"'..target..'"' or "nil")
                
                local parsedChoiceText, choiceEffects = Parser.parseTextWithTags(choiceText)
                
                local choice = {
                    text = choiceText,
                    parsedText = parsedChoiceText,
                    effects = choiceEffects,
                    target = target
                }
                
                if lines[currentLine - 1] then
                    table.insert(lines[currentLine - 1].choices, choice)
                    print("DEBUG: Added choice successfully")
                else
                    print("DEBUG: Warning - No previous line to attach choice to")
                end
            else
                print("DEBUG: Failed to parse choice line:", line)
            end
        elseif line:match("^%[.*%]") then
            currentScene = line:match("^%[(.*)%]")
            scenes[currentScene] = currentLine
        end
    end

    return lines, characters, scenes
end


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
