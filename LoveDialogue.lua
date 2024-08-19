local Parser = require "LoveDialogueParser"
local Constants = require "DialogueConstants"
local TextEffects = require "TextEffects"

local LoveDialogue = {}

function LoveDialogue:new()
    local obj = {
        lines = {},
        characters = {},
        currentLine = 1,
        isActive = false,
        font = love.graphics.newFont(Constants.DEFAULT_FONT_SIZE),
        nameFont = love.graphics.newFont(Constants.DEFAULT_NAME_FONT_SIZE),
        boxColor = Constants.BOX_COLOR,
        textColor = Constants.TEXT_COLOR,
        nameColor = Constants.NAME_COLOR,
        padding = Constants.PADDING,
        boxHeight = Constants.BOX_HEIGHT,
        typingSpeed = Constants.TYPING_SPEED,
        typewriterTimer = 0,
        displayedText = "",
        currentCharacter = "",
        boxOpacity = 0,
        fadeInDuration = Constants.FADE_IN_DURATION,
        fadeOutDuration = Constants.FADE_OUT_DURATION,
        animationTimer = 0,
        state = "inactive",
        effects = {},
        autoLayoutEnabled = true,
        waitTimer = 0,
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
        self.effects = {}
        self.waitTimer = 0
        for _, effect in ipairs(self.lines[self.currentLine].effects) do
            table.insert(self.effects, {
                type = effect.type,
                content = effect.content,
                startIndex = effect.startIndex,
                endIndex = effect.endIndex,
                timer = 0
            })
        end
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
            if self.waitTimer > 0 then
                self.waitTimer = self.waitTimer - dt
            else
                self.typewriterTimer = self.typewriterTimer + dt
                if self.typewriterTimer >= self.typingSpeed then
                    self.typewriterTimer = 0
                    local nextCharIndex = #self.displayedText + 1
                    local nextChar = string.sub(currentFullText, nextCharIndex, nextCharIndex)
                    self.displayedText = self.displayedText .. nextChar

                    -- Check for wait effect
                    for _, effect in ipairs(self.effects) do
                        if effect.type == "wait" and effect.startIndex == nextCharIndex then
                            self.waitTimer = tonumber(effect.content) or 0
                            break
                        end
                    end
                end
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

    -- Update effect timers
    for _, effect in ipairs(self.effects) do
        effect.timer = effect.timer + dt
    end

    -- Auto layout adjustment
    if self.autoLayoutEnabled then
        self:adjustLayout()
    end
end

function LoveDialogue:draw()
    if not self.isActive then return end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boxWidth = windowWidth - 2 * self.padding

    -- Draw dialogue box
    love.graphics.setColor(self.boxColor[1], self.boxColor[2], self.boxColor[3], self.boxColor[4] * self.boxOpacity)
    love.graphics.rectangle("fill", self.padding, windowHeight - self.boxHeight - self.padding, boxWidth, self.boxHeight)

    -- Draw character name
    love.graphics.setFont(self.nameFont)
    local nameColor = self.characters[self.currentCharacter]
    love.graphics.setColor(nameColor.r, nameColor.g, nameColor.b, self.boxOpacity)
    love.graphics.print(self.currentCharacter, self.padding * 2, windowHeight - self.boxHeight - self.padding + 10)

    -- Draw separator line
    love.graphics.setColor(1, 1, 1, 0.5 * self.boxOpacity)
    love.graphics.line(
        self.padding * 2, 
        windowHeight - self.boxHeight - self.padding + 35,
        boxWidth - self.padding * 2,
        windowHeight - self.boxHeight - self.padding + 35
    )

    -- Draw text
    love.graphics.setFont(self.font)
    local x = self.padding * 2
    local y = windowHeight - self.boxHeight + self.padding + 20
    local limit = boxWidth - self.padding * 2

    for i = 1, #self.displayedText do
        local char = self.displayedText:sub(i, i)
        local charWidth = self.font:getWidth(char)

        local color = {unpack(self.textColor)}
        local offset = {x = 0, y = 0}
        local scale = 1

        for _, effect in ipairs(self.effects) do
            if i >= effect.startIndex and i <= effect.endIndex then
                local effectFunc = TextEffects[effect.type]
                if effectFunc then
                    local effectColor, effectOffset = effectFunc(effect, char, i, effect.timer)
                    if effectColor then color = effectColor end
                    offset.x = offset.x + effectOffset.x
                    offset.y = offset.y + effectOffset.y
                    scale = scale * (effectOffset.scale or 1)
                end
            end
        end

        love.graphics.setColor(color[1], color[2], color[3], self.boxOpacity)
        love.graphics.print(char, x + offset.x, y + offset.y, 0, scale, scale)
        x = x + charWidth * scale

        if x > limit then
            x = self.padding * 2
            y = y + self.font:getHeight() * scale
        end
    end
end

function LoveDialogue:adjustLayout()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    self.boxHeight = math.floor(windowHeight * 0.25) -- 25% of screen height
    self.padding = math.floor(windowWidth * 0.02) -- 2% of screen width
    self.font = love.graphics.newFont(math.floor(windowHeight * 0.025)) -- Font size relative to screen height
    self.nameFont = love.graphics.newFont(math.floor(windowHeight * 0.03))
end

function LoveDialogue:advance()
    if self.state == "active" then
        if self.displayedText ~= self.lines[self.currentLine].text then
            self.displayedText = self.lines[self.currentLine].text
            self.waitTimer = 0
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