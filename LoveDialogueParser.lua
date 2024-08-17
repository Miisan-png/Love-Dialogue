local Parser = {}

function Parser.parseFile(filePath)
    local lines = {}
    local characters = {}
    
    for line in love.filesystem.lines(filePath) do
        local character, text = line:match("(.-):%s*(.*)")
        if character and text then
            table.insert(lines, {character = character, text = text})
            if not characters[character] then
                characters[character] = {r = love.math.random(), g = love.math.random(), b = love.math.random()}
            end
        end
    end
    
    return lines, characters
end

return Parser