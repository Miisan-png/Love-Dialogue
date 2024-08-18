local Parser = {}

function Parser.parseFile(filePath)
    local lines = {}
    local characters = {}
    
    for line in love.filesystem.lines(filePath) do
        local character, text = line:match("(.-):%s*(.*)")
        if character and text then
            local parsedLine = {character = character, text = "", effects = {}}
            local currentIndex = 1
            
            while true do
                local startTag, endTag, tag, content = text:find("%[([^:]+):([^%]]+)%]", currentIndex)
                
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
                local closingStart, closingEnd = text:find("%[/" .. tag .. "%]", endTag + 1)
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
            
            table.insert(lines, parsedLine)
            if not characters[character] then
                characters[character] = {r = love.math.random(), g = love.math.random(), b = love.math.random()}
            end
        end
    end
    
    return lines, characters
end

return Parser