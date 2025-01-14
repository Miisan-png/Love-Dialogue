--@class LD_Character
--@field public name string
--@field public color table
--@field public nameColor table
--@field public expressions table
--@field public portrait table
local LD_PATH = (...):match('(.-)[^%.]+$')
local LD_Character = require(LD_PATH .. "LD_Character")
local CharacterParser = {}

local function iwords(str)
    return string.gmatch(str, "%S+")
end

local function hexColorToRGB(hex)
    return {
        r = tonumber(string.sub(hex, 2, 3), 16) / 255,
        g = tonumber(string.sub(hex, 4, 5), 16) / 255,
        b = tonumber(string.sub(hex, 6, 7), 16) / 255
    }
end

-- Builds a portrait from a path and a number of rows and columns
-- @param path string
-- @param rows number
-- @param cols number
-- @returns table, string
local function buildPortrait(path, rows, cols)
    local success, image = pcall(love.graphics.newImage, path)

    if not success then
        return nil, "Could not load image"
    end

    local imageWidth = image:getWidth()
    local imageHeight = image:getHeight()
    local quadWidth = imageWidth / cols
    local quadHeight = imageHeight / rows
    local quads = {}

    for raw_x = 0, rows - 1 do
        for raw_y = 0, cols - 1 do
            local x = raw_x * quadHeight
            local y = raw_y * quadWidth
            local newQuad = love.graphics.newQuad(y, x, quadWidth, quadHeight, imageWidth, imageHeight)
            table.insert(quads, {
                quad = newQuad,
                texture = image
            })
        end
    end

    return quads, nil
end

local function parseCharacter(name, file)
    local character = LD_Character.new(name)
    local currentExpressionIndex = 1
    local portraits = nil

    while true do
        local currentLine = file:read("*line")
        if currentLine ~= nil then
            local nextWord = iwords(currentLine)
            local expr = nextWord()
            if expr == "@Name" then
                -- Seek one line before before returning the actual character
                file:seek("cur", -string.len(currentLine) - 2)
                break
            elseif expr == "@Portrait" then
                local path, rows, cols = currentLine:match("@Portrait%s+([%w%./_]+)%s+(%d+)%s+(%d+)")
                if path == nil or rows == nil or cols == nil then
                    return nil, "Incorrect portrait definition"
                end
                local portraitResult, buildPortraitError = buildPortrait(path, rows, cols)

                if buildPortraitError or portraitResult == nil then
                    return nil, buildPortraitError
                end
                portraits = portraitResult

                character:setDefaultExpression(portraits[1])
            elseif expr == "@Expression" then
                -- Tries matching "@Expression (Name) = (number or path)" and ignores whatever comes after that
                local expressionName, expressionPath = currentLine:match("@Expression%s+(%w+)%s*=%s*([^%s]+)")
                expressionName = expressionName or nextWord()
                if expressionName == nil then
                    return nil, "Invalid expression line"
                end
                -- Check if the expression path is a number or nil
                if expressionPath then
                    local expressionIndex = tonumber(expressionPath)
                    if expressionIndex ~= nil then
                        if portraits == nil or #portraits == 0 then
                            return nil,
                                "Tried to register an expression without a image path and without a portrait registered"
                        end

                        currentExpressionIndex = expressionIndex
                        character:addExpression(expressionName, portraits[currentExpressionIndex])
                        currentExpressionIndex = currentExpressionIndex + 1
                    else
                        local expressionResult, buildPortraitError = buildPortrait(expressionPath, 1, 1)
                        if buildPortraitError or expressionResult == nil then
                            return nil, buildPortraitError
                        end
                        character:addExpression(expressionName, expressionResult[1])
                    end
                else
                    if portraits == nil or #portraits == 0 then
                        return nil,
                            "Tried to register an expression without a image path and without a portrait registered"
                    end
                    character.expressions[expressionName] = portraits[currentExpressionIndex]
                    currentExpressionIndex = currentExpressionIndex + 1
                end
            elseif expr == "@NameColor" then
                local color = nextWord()
                -- Color must be in the format #RRGGBB, match it
                if color:match("#%x%x%x%x%x%x") then
                    character.nameColor = hexColorToRGB(color)
                else
                    return nil, "Invalid color format"
                end
            elseif expr == "@Color" then
                local color = nextWord()
                -- Color must be in the format #RRGGBB, match it
                if color:match("#%x%x%x%x%x%x") then
                    character.color = hexColorToRGB(color)
                else
                    return nil, "Invalid color format"
                end
            end
        else
            break
        end
    end

    return character, nil
end

-- LD_CharacterParser.lua
-- Parses a character file and returns a table of characters
-- @returns table, string
function CharacterParser.parseCharacter(filename)
    -- Extension must be a .char file
    if string.sub(filename, -5) ~= ".char" then
        return nil, "File must be a .char file"
    end

    local file, error = io.open(filename, "r")

    if error then
        return nil, error
    elseif file then
        local characters = {}

        local function parse()
            local currentLine = file:read("*line")
            -- First we check if it's a comment or a character. Otherwise, it's an error
            if currentLine == nil then
                return nil
            elseif string.sub(currentLine, 1, 2) == "--" then
                parse() -- Continue parsing
            elseif string.sub(currentLine, 1, 1) == "@" then
                -- It must be @Name, otherwise it's an error
                local nextWord = iwords(currentLine)
                local expr = nextWord()
                if expr == "@Name" then
                    local name = nextWord()
                    local character, parseCharacterError = parseCharacter(name, file)
                    if parseCharacterError then
                        return nil, error
                    end
                    table.insert(characters, character)
                    parse()
                end
            else
                return "Invalid character file"
            end
        end

        error = parse()

        file:close()

        if error then
            return nil, error
        end

        return characters, nil
    end
end

-- Parses a character file and returns a LD_Character object
-- @returns LD_Character, string
function CharacterParser.parseCharacterFromPortrait(name, filename)
    local portrait, error = buildPortrait(filename, 1, 1)

    if error or portrait == nil then
        return nil, error or "Could not load portrait"
    end

    return LD_Character.new(name, portrait[1]), nil
end

return CharacterParser