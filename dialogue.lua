local Dialogue = {}

-- Initialize the dialogue system
function Dialogue:new()
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
         -- Animation properties
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

-- Load dialogue from a .ld file
function Dialogue:loadFromFile(filePath)
    self.lines = {}
    self.characters = {}
    
    for line in love.filesystem.lines(filePath) do
        local character, text = line:match("(.-):%s*(.*)")
        if character and text then
            table.insert(self.lines, {character = character, text = text})
            if not self.characters[character] then
                self.characters[character] = {r = love.math.random(), g = love.math.random(), b = love.math.random()}
            end
        end
    end
end

-- Start the dialogue
function Dialogue:start()
    self.isActive = true
    self.currentLine = 1
    self:setCurrentDialogue()
end

-- Set the current dialogue line
function Dialogue:setCurrentDialogue()
    if self.currentLine <= #self.lines then
        self.currentCharacter = self.lines[self.currentLine].character
        self.displayedText = ""
        self.typewriterTimer = 0
    else
        self.isActive = false
    end
end

function Dialogue:update(dt)
    if not self.isActive then return end

    -- Update typewriter effect
    local currentFullText = self.lines[self.currentLine].text
    if self.displayedText ~= currentFullText then
        self.typewriterTimer = self.typewriterTimer + dt
        if self.typewriterTimer >= self.typingSpeed then
            self.typewriterTimer = 0
            local nextChar = string.sub(currentFullText, #self.displayedText + 1, #self.displayedText + 1)
            self.displayedText = self.displayedText .. nextChar
        end
    end

    -- Update animations
    self.animationTimer = math.min(self.animationTimer + dt, math.max(self.fadeInDuration, self.bounceNameDuration))
    
    -- Fade in effect
    self.boxOpacity = math.min(self.animationTimer / self.fadeInDuration, 1)
    
    -- Bounce effect for character name
    local bounceProgress = math.min(self.animationTimer / self.bounceNameDuration, 1)
    self.nameScale = math.sin(bounceProgress * math.pi) * 0.2 + 1  -- Scale between 1.0 and 1.2
end

function Dialogue:draw()
    if not self.isActive then return end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boxWidth = windowWidth - 2 * self.padding

    -- Draw dialogue box with fade-in effect
    love.graphics.setColor(self.boxColor[1], self.boxColor[2], self.boxColor[3], self.boxColor[4] * self.boxOpacity)
    love.graphics.rectangle("fill", self.padding, windowHeight - self.boxHeight - self.padding, boxWidth, self.boxHeight)

    -- Draw character name with bounce effect
    love.graphics.setFont(self.nameFont)
    local nameColor = self.characters[self.currentCharacter]
    love.graphics.setColor(nameColor.r, nameColor.g, nameColor.b, self.boxOpacity)
    
    love.graphics.push()
    love.graphics.translate(self.padding * 2, windowHeight - self.boxHeight - self.padding + 10)
    love.graphics.scale(self.nameScale, self.nameScale)
    love.graphics.print(self.currentCharacter, 0, 0)
    love.graphics.pop()

    -- Draw a line under the character name
    love.graphics.setColor(1, 1, 1, 0.5 * self.boxOpacity)
    love.graphics.line(
        self.padding * 2, 
        windowHeight - self.boxHeight - self.padding + 35,
        boxWidth - self.padding * 2,
        windowHeight - self.boxHeight - self.padding + 35
    )

    -- Draw text
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

function Dialogue:advance()
    if self.displayedText ~= self.lines[self.currentLine].text then
        -- If the current line hasn't finished typing, complete it
        self.displayedText = self.lines[self.currentLine].text
    else
        -- Move to the next line or end the dialogue
        self.currentLine = self.currentLine + 1
        self:setCurrentDialogue()
        -- Reset animation timer for new line
        self.animationTimer = 0
        self.boxOpacity = 0
        self.nameScale = 0
    end
end

-- Play dialogue from a file
function Dialogue.play(filePath)
    local dialogue = Dialogue:new()
    dialogue:loadFromFile(filePath)
    dialogue:start()
    return dialogue
end

return Dialogue