local Parser = {}
local LD_PATH = (...):match('(.-)[^%.]+$')
local PortraitManager = require(LD_PATH .. "PortraitManager")
local LD_Character = require(LD_PATH .. "LoveCharacter")
local CharacterParser = require(LD_PATH .. "LoveCharacterParser")
local FontManager = require(LD_PATH .. "FontManager")

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
        -- 解析开始标签 {font:name:size}
        local startTag, endTag, tag, content = text:find("{([^:}]+):([^}]*)}", currentIndex)
        -- 解析结束标签 {/font}
        local closingStartTag, closingEndTag, closingTag = text:find("{/([^}]+)}", currentIndex)

        -- 优先处理闭合标签
        if closingStartTag and (not startTag or closingStartTag < startTag) then
            parsedText = parsedText .. text:sub(currentIndex, closingStartTag - 1)
            
            -- 处理字体闭合标签
            if closingTag == "font" then
                for i = #openEffects, 1, -1 do
                    if openEffects[i].type == "font" then
                        local effect = table.remove(openEffects, i)
                        effect.endIndex = #parsedText
                        table.insert(effectsTable, effect)
                        break
                    end
                end
            end
            currentIndex = closingEndTag + 1

        -- 处理字体开始标签
        elseif startTag and tag == "font" then
            parsedText = parsedText .. text:sub(currentIndex, startTag - 1)
            local fontName, fontSize = content:match("([%w_]+):(%d+)")
            if fontName and fontSize then
                table.insert(openEffects, {
                    type = "font",
                    content = content,
                    startIndex = #parsedText + 1,
                    endIndex = nil -- 等待闭合标签
                })
            end
            currentIndex = endTag + 1

        -- 其他标签处理（如颜色、波浪效果等）
        elseif startTag then
            parsedText = parsedText .. text:sub(currentIndex, startTag - 1)
            table.insert(openEffects, {
                type = tag,
                content = content,
                startIndex = #parsedText + 1
            })
            currentIndex = endTag + 1

        else
            parsedText = parsedText .. text:sub(currentIndex)
            break
        end
    end

    -- 处理未闭合的标签
    for _, effect in ipairs(openEffects) do
        effect.endIndex = #parsedText
        -- 自动处理字体标签的覆盖范围
        if effect.type == "font" then
            for _, otherEffect in ipairs(effectsTable) do
                if otherEffect.type == "font" and otherEffect.startIndex > effect.startIndex then
                    effect.endIndex = otherEffect.startIndex - 1
                    break
                end
            end
        end
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
    
    local fileContent = love.filesystem.read(filePath)
    if not fileContent then
        error("Could not read file: " .. filePath)
        return
    end
    
    -- 第一遍解析：处理@指令
    for line in fileContent:gmatch("[^\r\n]+") do
        -- 处理字体注册
        local fontName, fontPath = line:match("^@font%s+(%S+)%s+(.+)")
        if fontName and fontPath then
            FontManager.registerFont(fontName, fontPath)
        end
        
        -- local characterName, path = line:match("^@portrait%s+(%S+)%s+(.+)$")
        -- if characterName and path then
        --     local character, error = CharacterParser.parseCharacterFromPortrait(characterName, path)
        --     if error or character == nil then
        --         print("Error parsing character file:", error)
        --     end
        --     characters[characterName] = character
        --     PortraitManager.loadPortrait(character, path:match("^%s*(.-)%s*$"))
        -- end
        
        local characterName, path, fontName = line:match("^@portrait%s+(%S+)%s+(%S+)%s*(%S*)")
        if characterName and path then
            local character, error = CharacterParser.parseCharacterFromPortrait(characterName, path)
            if error or character == nil then
                print("Error parsing character file:", error)
            else
                -- 设置角色名称字体（如果指定）
                if fontName and fontName ~= "" then
                    character.nameFont = fontName
                    print(string.format("[Parser] 角色 %s 名称字体设置为: %s", characterName, fontName))
                end
                characters[characterName] = character
                PortraitManager.loadPortrait(character, path:match("^%s*(.-)%s*$"))
            end
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

    -- 第二遍解析：处理对话内容
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
            line = line:gsub("[\r\n]", "")
            
            local choiceText, target = line:match("^%->%s*([^%[]+)%s*%[target:([%w_]+)%]%s*$")
            
            if choiceText then
                choiceText = choiceText:match("^%s*(.-)%s*$")
                target = target and target:match("^%s*(.-)%s*$")
                
                local parsedChoiceText, choiceEffects = Parser.parseTextWithTags(choiceText)
                
                local choice = {
                    text = choiceText,
                    parsedText = parsedChoiceText,
                    effects = choiceEffects,
                    target = target
                }
                
                if lines[currentLine - 1] then
                    table.insert(lines[currentLine - 1].choices, choice)
                end
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
