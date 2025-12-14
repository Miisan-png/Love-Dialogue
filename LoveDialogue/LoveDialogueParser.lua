local Parser = {}
local MODULE_PATH = (...):match('(.-)[^%.]+$')
local Character = require(MODULE_PATH .. "LoveCharacter")
local utf8 = require("utf8")

local function parseEffects(text)
    local clean, effects = "", {}
    local stack = {}
    local i = 1
    
    while i <= #text do
        local sTag, eTag, tag, content = text:find("{([^/}:]+):?([^}]*)}", i)
        local sClose, eClose, closeTag = text:find("{/([^}]+)}", i)
        
        if not sTag and not sClose then
            clean = clean .. text:sub(i)
            break
        end

        if sClose and (not sTag or sClose < sTag) then
            clean = clean .. text:sub(i, sClose - 1)
            for j = #stack, 1, -1 do
                if stack[j].type == closeTag then
                    local eff = table.remove(stack, j)
                    eff.endIndex = utf8.len(clean)
                    table.insert(effects, eff)
                    break
                end
            end
            i = eClose + 1
        else
            clean = clean .. text:sub(i, sTag - 1)
            table.insert(stack, {type = tag, content = content, startIndex = utf8.len(clean) + 1})
            i = eTag + 1
        end
    end
    return clean, effects
end

Parser.parseTextWithTags = parseEffects

function Parser.parseFile(path, instanceId)
    local lines, chars, scenes = {}, {}, {}
    local content = love.filesystem.read(path)
    if not content then return {}, {}, {} end
    
    local rawLines = {}
    for l in content:gmatch("[^\r\n]+") do table.insert(rawLines, l) end
    
    local i = 1
    for _, line in ipairs(rawLines) do
        local clean = line:match("^%s*(.-)%s*$")
        -- Skip empty lines and comments
        if clean ~= "" and not clean:match("^//") then
            
            -- 1. Portraits
            local pName, pPath = clean:match("^@portrait%s+(%S+)%s+(.+)$")
            if pName then
                if not chars[pName] then chars[pName] = Character.new(pName, instanceId) end
                chars[pName]:loadExpression("Default", pPath, 1, 1, 1)
            
            -- 2. Logic Commands (Variable Assignment)
            elseif clean:match("^%$") then
                local statement = clean:match("^%$%s*(.+)$")
                table.insert(lines, {
                    type = "command",
                    statement = statement
                })

            -- 3. Flow Control: IF
            elseif clean:match("^%[if:.+%]$)"
                local condition = clean:match("^%[if:%s*(.+)%]$)"
                table.insert(lines, {
                    type = "block_if",
                    condition = condition
                })

            -- 4. Flow Control: ELSE
            elseif clean:match("^%[else%]$)"
                table.insert(lines, { type = "block_else" })

            -- 5. Flow Control: ENDIF
            elseif clean:match("^%[endif%]$)"
                table.insert(lines, { type = "block_endif" })
            
            -- NEW 6. Signals: [signal: Name Args]
            elseif clean:match("^%[signal:.+%]$)"
                local signalContent = clean:match("^%[signal:%s*(.+)%]$)"
                -- Parse "Name Arg1 Arg2..."
                local name, args = signalContent:match("^(%S+)%s*(.*)$")
                table.insert(lines, {
                    type = "signal",
                    name = name,
                    args = args -- Raw arg string, can be parsed later or passed as is
                })

            -- 7. Scene Labels
            elseif clean:match("^%[.*%]$)"
                local sName = clean:match("^%[(.*)%]$)"
                scenes[sName] = #lines + 1 -- Point to the next line index
            
            -- 8. Choices
            elseif clean:match("^%->") then
                local txt, remainder = clean:match("^%->%s*([^%[]+)%s*(.*)$")
                
                if txt and lines[#lines] then
                    local target = remainder:match("%[target:([%w_]+)%]")
                    local condition = remainder:match("%[if:%s*(.-)%]")
                    local pText, eff = parseEffects(txt)
                    
                    if lines[#lines].type == "dialogue" then
                        table.insert(lines[#lines].choices, { 
                            text = txt, 
                            parsedText = pText, 
                            effects = eff, 
                            target = target,
                            condition = condition
                        })
                    else
                        print("Warning: Choice found without preceding dialogue at line " .. i)
                    end
                end
            
            -- 9. Dialogue
            else
                local name, expr, text = clean:match("^(%S-)(%b()):%s*(.+)$")
                if not name then name, text = clean:match("^(%S+):%s*(.+)$") end
                
                if name then
                    if expr then expr = expr:sub(2, -2) end
                    if not chars[name] then chars[name] = Character.new(name, instanceId) end
                    
                    local isEnd = text:match("%s*%(end%)$")
                    if isEnd then text = text:gsub("%s*%(end%)$", "") end
                    
                    local pText, eff = parseEffects(text)
                    table.insert(lines, {
                        type = "dialogue",
                        character = name,
                        expression = expr,
                        text = pText,      
                        rawText = text,    
                        effects = eff,
                        isEnd = isEnd ~= nil,
                        choices = {}
                    })
                end
            end
        end
    end
    return lines, chars, scenes
end

return Parser
