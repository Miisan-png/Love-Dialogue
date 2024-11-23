local Parser = require "LoveDialogueParser"
local Constants = require "DialogueConstants"
local TextEffects = require "TextEffects"
local ThemeParser = require "ThemeParser"  
local PortraitManager = require "PortraitManager"

local LoveDialogue = {}

function LoveDialogue:new(config)
    config = config or {} 
    local obj = {
        lines = {},
        characters = {},
        currentLine = 1,
        selectedChoice = 1,
        isActive = false,
        font = love.graphics.newFont(config.fontSize or Constants.DEFAULT_FONT_SIZE),
        nameFont = love.graphics.newFont(config.nameFontSize or Constants.DEFAULT_NAME_FONT_SIZE),
        boxColor = config.boxColor or {0.1, 0.1, 0.1, 0.9},
        textColor = config.textColor or {1, 1, 1, 1},
        nameColor = config.nameColor or {1, 0.8, 0.2, 1},
        padding = config.padding or 20,
        boxHeight = config.boxHeight or 150,
        portraitSize = config.portraitSize or 100,  -- Added this line
        typingSpeed = config.typingSpeed or Constants.TYPING_SPEED,
        typewriterTimer = 0,
        displayedText = "",
        currentCharacter = "",
        boxOpacity = 0,
        fadeInDuration = config.fadeInDuration or Constants.FADE_IN_DURATION,
        fadeOutDuration = config.fadeOutDuration or Constants.FADE_OUT_DURATION,
        animationTimer = 0,
        state = "inactive",
        enableFadeIn = config.enableFadeIn or true,
        enableFadeOut = config.enableFadeOut or true,
        effects = {},
        currentBranch = nil,
        selectedBranchIndex = 1,
        waitTimer = 0,
        autoLayoutEnabled = config.autoLayoutEnabled or true,
        choiceMode = false,
        portraitEnabled = config.portraitEnabled ~= false,
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end




function LoveDialogue:loadFromFile(filePath)
    self.lines, self.characters, self.scenes = Parser.parseFile(filePath)
end

function LoveDialogue:start()
    self.isActive = true
    self.currentLine = 1
    self.state = self.enableFadeIn and "fading_in" or "active"
    self.animationTimer = 0
    self.boxOpacity = self.enableFadeIn and 0 or 1
    self:setCurrentDialogue()
end

function LoveDialogue:setCurrentDialogue()
    local currentDialogue = self.lines[self.currentLine]
    if currentDialogue then
        self.currentCharacter = currentDialogue.character
        self.displayedText = ""
        self.typewriterTimer = 0
        self.effects = {}
        self.waitTimer = 0
        self.choiceMode = currentDialogue.choices and #currentDialogue.choices > 0
        
        if self.choiceMode then
            self.displayedText = currentDialogue.text
            self.selectedChoice = 1
            
            -- Apply effects to choices
            for _, choice in ipairs(currentDialogue.choices) do
                local text, effects = Parser.parseTextWithTags(choice.text)
                choice.parsedText = text
                choice.effects = effects
            end
        end

        if currentDialogue.effects then
            for _, effect in ipairs(currentDialogue.effects) do
                table.insert(self.effects, {
                    type = effect.type,
                    content = effect.content,
                    startIndex = effect.startIndex,
                    endIndex = effect.endIndex,
                    timer = 0
                })
            end
        end
    else
        self:endDialogue()
    end
end



function LoveDialogue:draw()
    if not self.isActive then return end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boxWidth = windowWidth - 2 * self.padding
    
    love.graphics.setColor(self.boxColor[1], self.boxColor[2], self.boxColor[3], self.boxColor[4] * self.boxOpacity)
    love.graphics.rectangle("fill", self.padding, windowHeight - self.boxHeight - self.padding, boxWidth, self.boxHeight)

    local textX = self.padding * 2
    local textY = windowHeight - self.boxHeight - self.padding + self.padding
    local textLimit = boxWidth - (self.padding * 3)

    local hasPortrait = self.portraitEnabled and self.currentCharacter and 
                       PortraitManager.hasPortrait(self.currentCharacter)
    
    if hasPortrait then
        -- Draw portrait
        local portrait = PortraitManager.getPortrait(self.currentCharacter)
        local portraitX = self.padding * 2
        local portraitY = windowHeight - self.boxHeight - self.padding + self.padding
        
        love.graphics.setColor(0, 0, 0, self.boxOpacity * 0.5)
        love.graphics.rectangle("fill", portraitX, portraitY, self.portraitSize, self.portraitSize)
        
        love.graphics.setColor(1, 1, 1, self.boxOpacity)
        love.graphics.draw(portrait, portraitX, portraitY, 0, 
            self.portraitSize / portrait:getWidth(), 
            self.portraitSize / portrait:getHeight())

        textX = self.padding * 3 + self.portraitSize
        textLimit = boxWidth - self.portraitSize - (self.padding * 4)
    end

    if self.currentCharacter and self.currentCharacter ~= "" then
        love.graphics.setFont(self.nameFont)
        local nameColor = self.characters[self.currentCharacter] or self.nameColor
        love.graphics.setColor(nameColor.r or nameColor[1], nameColor.g or nameColor[2], 
                             nameColor.b or nameColor[3], self.boxOpacity)
        love.graphics.print(self.currentCharacter, textX, textY)
        textY = textY + self.nameFont:getHeight() + 5
    end

    love.graphics.setFont(self.font)
    if self.choiceMode then
        for i, choice in ipairs(self.lines[self.currentLine].choices) do
            local prefix = (i == self.selectedChoice) and "> " or "  "
            local x = textX + self.font:getWidth(prefix)
            local y = textY + (i - 1) * (self.font:getHeight() + 5)
            
            local choiceColor = (i == self.selectedChoice) and {1, 1, 0, self.boxOpacity} or {1, 1, 1, self.boxOpacity}
            love.graphics.setColor(unpack(choiceColor))
            love.graphics.print(prefix, textX, y)
            
            if choice.parsedText then
                for charIndex = 1, #choice.parsedText do
                    local char = choice.parsedText:sub(charIndex, charIndex)
                    local color = choiceColor
                    local offset = {x = 0, y = 0, scale = 1}

                    if choice.effects then
                        for _, effect in ipairs(choice.effects) do
                            if charIndex >= effect.startIndex and charIndex <= effect.endIndex then
                                local effectFunc = TextEffects[effect.type]
                                if effectFunc then
                                    local effectColor, effectOffset = effectFunc(effect, char, charIndex, love.timer.getTime())
                                    if effectColor then color = effectColor end
                                    offset.x = offset.x + (effectOffset.x or 0)
                                    offset.y = offset.y + (effectOffset.y or 0)
                                    offset.scale = offset.scale * (effectOffset.scale or 1)
                                end
                            end
                        end
                    end

                    love.graphics.setColor(unpack(color))
                    love.graphics.print(char, x + offset.x, y + offset.y, 0, offset.scale, offset.scale)
                    x = x + self.font:getWidth(char) * offset.scale
                end
            end
        end
    else
        -- Draw regular text
        local x = textX
        local y = textY
        local baseColor = {self.textColor[1], self.textColor[2], self.textColor[3], self.textColor[4] * self.boxOpacity}
        
        for charIndex = 1, #self.displayedText do
            local char = self.displayedText:sub(charIndex, charIndex)
            local color = baseColor
            local offset = {x = 0, y = 0, scale = 1}

            for _, effect in ipairs(self.effects) do
                if charIndex >= effect.startIndex and charIndex <= effect.endIndex then
                    local effectFunc = TextEffects[effect.type]
                    if effectFunc then
                        local effectColor, effectOffset = effectFunc(effect, char, charIndex, love.timer.getTime())
                        if effectColor then color = effectColor end
                        offset.x = offset.x + (effectOffset.x or 0)
                        offset.y = offset.y + (effectOffset.y or 0)
                        offset.scale = offset.scale * (effectOffset.scale or 1)
                    end
                end
            end

            if x + self.font:getWidth(char) * offset.scale > textX + textLimit then
                x = textX
                y = y + self.font:getHeight() * offset.scale
            end

            love.graphics.setColor(unpack(color))
            love.graphics.print(char, x + offset.x, y + offset.y, 0, offset.scale, offset.scale)
            x = x + self.font:getWidth(char) * offset.scale
        end
    end
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
        if not self.choiceMode then
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

    if self.autoLayoutEnabled then
        self:adjustLayout()
    end
end

function LoveDialogue:advance()
    if self.state ~= "active" then
        if self.state == "fading_in" then
            self.state = "active"
            self.boxOpacity = 1
        end
        return
    end

    if self.choiceMode then
        -- Add nil checks for choices
        if not self.lines[self.currentLine] then
            print("Warning: Current line is nil")
            return
        end
        
        if not self.lines[self.currentLine].choices then
            print("Warning: No choices available for current line")
            return
        end

        local selectedChoice = self.lines[self.currentLine].choices[self.selectedChoice]
        if not selectedChoice then
            print("Warning: Selected choice is nil")
            return
        end

        -- Add debug print
        print("Processing choice:", selectedChoice.text)
        
        if selectedChoice.callback then
            print("Executing callback for choice:", selectedChoice.text)
            local success, err = pcall(selectedChoice.callback)
            if not success then
                print("Error executing callback:", err)
            end
        end
        
        if selectedChoice.target and self.scenes and self.scenes[selectedChoice.target] then
            self.currentLine = self.scenes[selectedChoice.target]
        else
            self.currentLine = self.currentLine + 1
        end
        self.selectedChoice = 1
        self:setCurrentDialogue()
    else
        if not self.lines[self.currentLine] then
            print("Warning: Current line is nil")
            return
        end

        if self.displayedText ~= self.lines[self.currentLine].text then
            self.displayedText = self.lines[self.currentLine].text
        else
            if self.lines[self.currentLine].isEnd then
                self:endDialogue()
            else
                self.currentLine = self.currentLine + 1
                self:setCurrentDialogue()
            end
        end
    end
end

-- Also update setCurrentDialogue() to include defensive checks:
function LoveDialogue:setCurrentDialogue()
    local currentDialogue = self.lines[self.currentLine]
    if not currentDialogue then
        print("Warning: No dialogue found for line", self.currentLine)
        self:endDialogue()
        return
    end

    self.currentCharacter = currentDialogue.character or ""
    self.displayedText = ""
    self.typewriterTimer = 0
    self.effects = {}
    self.waitTimer = 0
    self.choiceMode = currentDialogue.choices and #currentDialogue.choices > 0
    
    if self.choiceMode then
        self.displayedText = currentDialogue.text or ""
        self.selectedChoice = 1
        
        if currentDialogue.choices then
            for _, choice in ipairs(currentDialogue.choices) do
                if choice and choice.text then
                    local text, effects = Parser.parseTextWithTags(choice.text)
                    choice.parsedText = text
                    choice.effects = effects
                end
            end
        end
    end

    if currentDialogue.effects then
        for _, effect in ipairs(currentDialogue.effects) do
            if effect then
                table.insert(self.effects, {
                    type = effect.type,
                    content = effect.content,
                    startIndex = effect.startIndex,
                    endIndex = effect.endIndex,
                    timer = 0
                })
            end
        end
    end
end

function LoveDialogue:keypressed(key)
    if not self.isActive then return end

    if self.choiceMode then
        if key == "up" then
            self.selectedChoice = math.max(1, self.selectedChoice - 1)
        elseif key == "down" then
            self.selectedChoice = math.min(#self.lines[self.currentLine].choices, self.selectedChoice + 1)
        elseif key == "return" or key == "space" then
            self:advance()
        end
    else
        if key == "return" or key == "space" then
            self:advance()
        end
    end
end

function LoveDialogue:endDialogue()
    self.state = self.enableFadeOut and "fading_out" or "inactive"
    self.animationTimer = 0
    if not self.enableFadeOut then
        self.isActive = false
    end
end

function LoveDialogue:adjustLayout()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    self.boxHeight = math.floor(windowHeight * 0.25)
    self.padding = math.floor(windowWidth * 0.02)
    self.font = love.graphics.newFont(math.floor(windowHeight * 0.025))
    self.nameFont = love.graphics.newFont(math.floor(windowHeight * 0.03))
end

function LoveDialogue.play(filePath, config)
    local dialogue = LoveDialogue:new(config or {})
    if config and config.theme then
        dialogue:loadTheme(config.theme)
    end
    dialogue:loadFromFile(filePath)
    dialogue:start()
    return dialogue
end

return LoveDialogue