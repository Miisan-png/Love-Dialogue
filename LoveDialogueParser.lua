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
            lines[currentLine] = {character = character, text = text, isEnd = isEnd, branches = nil}
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

return Parser