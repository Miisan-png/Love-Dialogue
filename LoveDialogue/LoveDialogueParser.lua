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
        if clean ~= "" and not clean:match("^//") then
            
            -- 1. Portraits
            local pName, pPath = clean:match('^@portrait%s+(%S+)%s+(.+)$')
            if pName then
                if not chars[pName] then chars[pName] = Character.new(pName, instanceId) end
                chars[pName]:loadExpression("Default", pPath, 1, 1, 1)
            
            -- 1b. Sprite Sheets
            elseif clean:match('^@sheet%s+') then
                local name, path, fw, fh = clean:match('^@sheet%s+(%S+)%s+(%S+)%s+(%d+)%s+(%d+)')
                if name and path then
                    if not chars[name] then chars[name] = Character.new(name, instanceId) end
                    chars[name]:defineSheet(path, tonumber(fw), tonumber(fh))
                end

            -- 1c. Sprite Frames
            elseif clean:match('^@frame%s+') then
                local name, expr, idx = clean:match('^@frame%s+(%S+)%s+(%S+)%s+(%d+)')
                if name and expr and idx and chars[name] then
                    chars[name]:addFrame(expr, tonumber(idx))
                end

            -- 1d. Atlas
            elseif clean:match('^@atlas%s+') then
                local name, path = clean:match('^@atlas%s+(%S+)%s+(%S+)')
                if name and path then
                    if not chars[name] then chars[name] = Character.new(name, instanceId) end
                    chars[name]:defineAtlas(path)
                end

            -- 1e. Rect
            elseif clean:match('^@rect%s+') then
                local name, expr, x, y, w, h = clean:match('^@rect%s+(%S+)%s+(%S+)%s+(%-?%d+)%s+(%-?%d+)%s+(%d+)%s+(%d+)')
                if name and expr and x and y and w and h and chars[name] then
                    chars[name]:addRect(expr, tonumber(x), tonumber(y), tonumber(w), tonumber(h))
                else
                    print("Warning: Failed to parse @rect line: '" .. clean .. "'")
                end

            -- 2. Commands
            elseif clean:match('^%$') then
                local statement = clean:match('^%$%s*(.+)$')
                table.insert(lines, { type = "command", statement = statement })

            -- 3. Flow Control
            elseif clean:match('^%[if:.+%]$') then
                local condition = clean:match('^%[if:%s*(.+)%]$')
                table.insert(lines, { type = "block_if", condition = condition })

            elseif clean:match('^%[else%]$') then
                table.insert(lines, { type = "block_else" })

            elseif clean:match('^%[endif%]$') then
                table.insert(lines, { type = "block_endif" })
            
            -- 6. Signals
            elseif clean:match('^%[signal:.+%]$') then
                local signalContent = clean:match('^%[signal:%s*(.+)%]$')
                local name, args = signalContent:match('^(%S+)%s*(.*)$')
                table.insert(lines, { type = "signal", name = name, args = args })
            
            -- 7. Theme
            elseif clean:match('^%[load_theme:.+%]$') then
                local themePath = clean:match('^%[load_theme:%s*(.+)%]$')
                table.insert(lines, { type = "theme_load", path = themePath })

            -- 8. Labels
            elseif clean:match('^%[.*%]$') then
                local sName = clean:match('^%[(.*)%]$')
                scenes[sName] = #lines + 1
            
            -- 9. Choices
            elseif clean:match('^%->') then
                local txt, remainder = clean:match('^%->%s*([^%[]+)%s*(.*)$')
                if txt and lines[#lines] then
                    local target = remainder:match('%[target:([%w_]+)%]')
                    local condition = remainder:match('%[if:%s*(.-)%]')
                    local pText, eff = parseEffects(txt)
                    if lines[#lines].type == "dialogue" then
                        table.insert(lines[#lines].choices, { text = txt, parsedText = pText, effects = eff, target = target, condition = condition })
                    end
                end
            
            -- 10. Dialogue
            else
                local name, expr, text
                
                -- Style 1: Name(Expression): Text
                name, expr, text = clean:match('^(%S-)(%b()):%s*(.+)$')
                if expr then expr = expr:sub(2, -2) end -- strip parens
                
                -- Style 2: Name: (Expression) Text
                if not name then
                    local tName, tExpr, tText = clean:match('^(%S+):%s*(%b())%s*(.+)$')
                    if tName and tExpr and tText then
                        name = tName
                        expr = tExpr:sub(2, -2) -- strip parens
                        text = tText
                    end
                end
                
                -- Style 3: Name: Text (Default expression)
                if not name then 
                    name, text = clean:match('^(%S+):%s*(.+)$') 
                end
                
                if name then
                    if not chars[name] then chars[name] = Character.new(name, instanceId) end
                    
                    local isEnd = text:match('%s*%(end%)$')
                    if isEnd then text = text:gsub('%s*%(end%)$', "") end
                    
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