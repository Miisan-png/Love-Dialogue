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
        nameScale = 0,
        fadeInDuration = 0.5,
        bounceNameDuration = 0.3,
        animationTimer = 0,
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
    self:setCurrentDialogue()
end

function LoveDialogue:setCurrentDialogue()
    if self.currentLine <= #self.lines then
        self.currentCharacter = self.lines[self.currentLine].character
        self.displayedText = ""
        self.typewriterTimer = 0
    else
        self.isActive = false
    end
end

function LoveDialogue:update(dt)
    if not self.isActive then return end

    local currentFullText = self.lines[self.currentLine].text
    if self.displayedText ~= currentFullText then
        self.typewriterTimer = self.typewriterTimer + dt
        if self.typewriterTimer >= self.typingSpeed then
            self.typewriterTimer = 0
            local nextChar = string.sub(currentFullText, #self.displayedText + 1, #self.displayedText + 1)
            self.displayedText = self.displayedText .. nextChar
        end
    end

    self.animationTimer = math.min(self.animationTimer + dt, math.max(self.fadeInDuration, self.bounceNameDuration))
    self.boxOpacity = math.min(self.animationTimer / self.fadeInDuration, 1)
    local bounceProgress = math.min(self.animationTimer / self.bounceNameDuration, 1)
    self.nameScale = math.sin(bounceProgress * math.pi) * 0.2 + 1
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
    
    love.graphics.push()
    love.graphics.translate(self.padding * 2, windowHeight - self.boxHeight - self.padding + 10)
    love.graphics.scale(self.nameScale, self.nameScale)
    love.graphics.print(self.currentCharacter, 0, 0)
    love.graphics.pop()

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
    if self.displayedText ~= self.lines[self.currentLine].text then
        self.displayedText = self.lines[self.currentLine].text
    else
        self.currentLine = self.currentLine + 1
        self:setCurrentDialogue()
        self.animationTimer = 0
        self.boxOpacity = 0
        self.nameScale = 0
    end
end

function LoveDialogue.play(filePath)
    local dialogue = LoveDialogue:new()
    dialogue:loadFromFile(filePath)
    dialogue:start()
    return dialogue
end

return LoveDialogue