local LoveDialogue = {}
local Parser = require "LoveDialogueParser"

function LoveDialogue:new()
    local obj = {
        lines = {},
        characters = {},
        currentLine = 1,
        isActive = false,
        font = love.graphics.newFont(16),
        nameFont = love.graphics.newFont(18),
        boxColor = {0.1, 0.1, 0.1, 0.8},
        textColor = {1, 1, 1, 1},
        nameColor = {0.8, 0.8, 0.2, 1},
        padding = 10,
        boxHeight = 120,
        typingSpeed = 0.05,
        typewriterTimer = 0,
        displayedText = "",
        currentCharacter = "",
        boxOpacity = 0,
        fadeInDuration = 0.5,
        fadeOutDuration = 0.5,
        animationTimer = 0,
        state = "inactive", -- Can be "inactive", "fading_in", "active", "fading_out"
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function LoveDialogue:loadFromFile(filePath)
    self.lines, self.characters = Parser.parseFile(filePath)
end

function LoveDialogue:start()
    self.isActive = true
    self.currentLine = 1
    self.state = "fading_in"
    self.animationTimer = 0
    self.boxOpacity = 0
    self:setCurrentDialogue()
end

function LoveDialogue:setCurrentDialogue()
    if self.currentLine <= #self.lines then
        self.currentCharacter = self.lines[self.currentLine].character
        self.displayedText = ""
        self.typewriterTimer = 0
    else
        self:endDialogue()
    end
end

function LoveDialogue:endDialogue()
    self.state = "fading_out"
    self.animationTimer = 0
end

function LoveDialogue:update(dt)
    if not self.isActive then return end

    if self.state == "fading_in" then
        self.animationTimer = self.animationTimer + dt
        self.boxOpacity = math.min(self.animationTimer / self.fadeInDuration, 1)
        if self.animationTimer >= self.fadeInDuration then
            self.state = "active"
        end
    elseif self.state == "active" then
        local currentFullText = self.lines[self.currentLine].text
        if self.displayedText ~= currentFullText then
            self.typewriterTimer = self.typewriterTimer + dt
            if self.typewriterTimer >= self.typingSpeed then
                self.typewriterTimer = 0
                local nextChar = string.sub(currentFullText, #self.displayedText + 1, #self.displayedText + 1)
                self.displayedText = self.displayedText .. nextChar
            end
        end
    elseif self.state == "fading_out" then
        self.animationTimer = self.animationTimer + dt
        self.boxOpacity = 1 - math.min(self.animationTimer / self.fadeOutDuration, 1)
        if self.animationTimer >= self.fadeOutDuration then
            self.isActive = false
            self.state = "inactive"
        end
    end
end

function LoveDialogue:draw()
    if not self.isActive then return end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boxWidth = windowWidth - 2 * self.padding

    love.graphics.setColor(self.boxColor[1], self.boxColor[2], self.boxColor[3], self.boxColor[4] * self.boxOpacity)
    love.graphics.rectangle("fill", self.padding, windowHeight - self.boxHeight - self.padding, boxWidth, self.boxHeight)

    love.graphics.setFont(self.nameFont)
    local nameColor = self.characters[self.currentCharacter]
    love.graphics.setColor(nameColor.r, nameColor.g, nameColor.b, self.boxOpacity)
    love.graphics.print(self.currentCharacter, self.padding * 2, windowHeight - self.boxHeight - self.padding + 10)

    love.graphics.setColor(1, 1, 1, 0.5 * self.boxOpacity)
    love.graphics.line(
        self.padding * 2, 
        windowHeight - self.boxHeight - self.padding + 35,
        boxWidth - self.padding * 2,
        windowHeight - self.boxHeight - self.padding + 35
    )

    love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.textColor[4] * self.boxOpacity)
    love.graphics.setFont(self.font)
    love.graphics.printf(
        self.displayedText, 
        self.padding * 2, 
        windowHeight - self.boxHeight + self.padding + 20,
        boxWidth - self.padding * 2, 
        "left"
    )
end

function LoveDialogue:advance()
    if self.state == "active" then
        if self.displayedText ~= self.lines[self.currentLine].text then
            self.displayedText = self.lines[self.currentLine].text
        else
            self.currentLine = self.currentLine + 1
            self:setCurrentDialogue()
        end
    elseif self.state == "fading_in" then
        self.state = "active"
        self.boxOpacity = 1
    end
end

function LoveDialogue.play(filePath)
    local dialogue = LoveDialogue:new()
    dialogue:loadFromFile(filePath)
    dialogue:start()
    return dialogue
end

return LoveDialogue