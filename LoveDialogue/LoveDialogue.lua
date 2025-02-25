local utf8 = require("utf8")
local LD_PATH = (...):match('(.-)[^%.]+$')

local font1 = love.graphics.newFont("assets/font/fusion-pixel-8px-monospaced-zh_hans.ttf", 16)

local Parser = require(LD_PATH .. "LoveDialogueParser")
local Constants = require(LD_PATH .. "DialogueConstants")
local TextEffects = require(LD_PATH .. "TextEffects")
local ThemeParser = require(LD_PATH .. "ThemeParser")  

local LoveDialogue = {}
LoveDialogue.callbackHandler = require(LD_PATH .. "CallbackHandler")

local ninePatch = require(LD_PATH .. "9patch")

local function isCJK(char)
    local codepoint = utf8.codepoint(char)
    return (codepoint >= 0x4E00 and codepoint <= 0x9FFF) or   -- 基本汉字
           (codepoint >= 0x3400 and codepoint <= 0x4DBF) or   -- 扩展A
           (codepoint >= 0x20000 and codepoint <= 0x2A6DF)    -- 扩展B
end

function LoveDialogue:new(config)
    config = config or {} 
    ---@class LoveDialogue
    ---@field characters table<string, LD_Character>
    local obj = {
        lines = {},
        characters = {},
        boxtype = true, -- 0=原本的框，1=9宫格框
        character_type = false,--0=原本的角色显示，1=竖直显示
        currentLine = 1,
        selectedChoice = 1,
        isActive = false,
        letterSpacingLatin = config.letterSpacingLatin or 4,  -- 西文字符间距
        letterSpacingCJK = config.letterSpacingCJK or 10,      -- 汉字字符间距
        lineSpacing = config.lineSpacing or 16,      -- 行间距
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
        ninePatchImage = nil,  -- 新增：九宫格图片
        patch = nil,           -- 新增：九宫格对象
    }
    setmetatable(obj, self)
    self.__index = self

    -- 加载九宫格图片
    if obj.boxtype == true then
        obj.ninePatchImage = love.graphics.newImage("assets/9.png")
        obj:createNinePatchQuads()  -- 调用修改后的方法
    end

    return obj
end

function LoveDialogue:createNinePatchQuads()
    -- 确保只在需要时加载图片
    if not self.ninePatchImage then
        self.ninePatchImage = love.graphics.newImage("assets/9.png")
    end
    
    -- 确认图片有效
    if self.ninePatchImage and self.ninePatchImage:typeOf("Image") then
        local edgeWidth = 10
        local edgeHeight = 10
        self.patch = ninePatch.loadSameEdge(self.ninePatchImage, edgeWidth, edgeHeight)
    else
        print("Error: Failed to load ninePatchImage")
    end
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

function LoveDialogue:draw()
    if not self.isActive then return end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boxWidth = windowWidth - 2 * self.padding

    if self.character_type then
        if self.portraitEnabled and self.currentCharacter and self.characters[self.currentCharacter]:hasPortrait() then
            local portrait = self.characters[self.currentCharacter]:getExpression(self.currentExpression)
            local sw, sh = portrait.quad:getTextureDimensions()
            
            -- 计算原始尺寸的绘制位置
            local portraitX = (windowWidth - sw)/2
            --local portraitY = (windowHeight - sh)/2
            local portraitY = windowHeight - sh

            love.graphics.setColor(1, 1, 1, self.boxOpacity)
            self.characters[self.currentCharacter]:draw(
                self.currentExpression,
                portraitX,
                portraitY,
                1,  -- (不缩放)
                1
            )
        end
    end

    -- 绘制对话框（后绘制对话框以覆盖在头像上方）
    if self.boxtype == false then
        love.graphics.setColor(self.boxColor[1], self.boxColor[2], self.boxColor[3], self.boxColor[4] * self.boxOpacity)
        love.graphics.rectangle("fill", self.padding, windowHeight - self.boxHeight - self.padding, boxWidth, self.boxHeight)
    else
        if self.patch then
            ninePatch.draw(self.patch, self.padding, windowHeight - self.boxHeight - self.padding, boxWidth, self.boxHeight)
        end
    end

    local textX = self.padding * 2
    local textY = windowHeight - self.boxHeight - self.padding + self.padding
    local textLimit = boxWidth - (self.padding * 3)

    -- 根据 character_type 决定是否绘制角色头像
    local hasPortrait = false
    if not self.character_type then
        hasPortrait = self.portraitEnabled and self.currentCharacter and self.characters[self.currentCharacter]:hasPortrait()
    end

    if hasPortrait and not self.character_type then
        -- Draw portrait
        local portrait = self.characters[self.currentCharacter]:getExpression(self.currentExpression)
        local portraitX = self.padding * 2
        local portraitY = windowHeight - self.boxHeight - self.padding + self.padding
        local sw, sh = portrait.quad:getTextureDimensions()

        love.graphics.setColor(0, 0, 0, self.boxOpacity * 0.5)
        love.graphics.rectangle("fill", portraitX, portraitY, self.portraitSize, self.portraitSize)
        
        love.graphics.setColor(1, 1, 1, self.boxOpacity)
        self.characters[self.currentCharacter]:draw(self.currentExpression, portraitX, portraitY, self.portraitSize / sw, self.portraitSize / sh)
        textX = self.padding * 3 + self.portraitSize
        textLimit = boxWidth - self.portraitSize - (self.padding * 4)
    end

    if self.currentCharacter and self.currentCharacter ~= "" then--检测角色名是否非空白
        love.graphics.setFont(self.nameFont)
        local nameColor = self.characters[self.currentCharacter].nameColor or self.nameColor
        love.graphics.setColor(nameColor.r or nameColor[1], nameColor.g or nameColor[2], 
                             nameColor.b or nameColor[3], self.boxOpacity)
        love.graphics.print(self.currentCharacter, font1, textX, textY)
        textY = textY + self.nameFont:getHeight() + 5
    end

    love.graphics.setFont(self.font)
    if self.choiceMode then
        for i, choice in ipairs(self.lines[self.currentLine].choices) do
            local prefix = (i == self.selectedChoice) and "> " or "  "
            local x = textX + self.font:getWidth(prefix)
            local y = textY + (i - 1) * self.lineSpacing  -- 行间距
            
            local choiceColor = (i == self.selectedChoice) and {1, 1, 0, self.boxOpacity} or {1, 1, 1, self.boxOpacity}
            love.graphics.setColor(unpack(choiceColor))
            love.graphics.print(prefix, font1, textX, y)
            
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
                    love.graphics.print(char, font1, x + offset.x, y + offset.y, 0, offset.scale, offset.scale)
                    local charTypeSpacing = isCJK(char) and self.letterSpacingCJK or self.letterSpacingLatin
                    x = x + self.font:getWidth(char) * offset.scale + charTypeSpacing
                end
            end
        end
    else
        -- Draw regular text
        local x = textX
        local y = textY
        
        local baseColor = {self.textColor[1], self.textColor[2], self.textColor[3], self.textColor[4] * self.boxOpacity}
        
        for pos, char in utf8.codes(self.displayedText) do
            local char = utf8.char(char)
            local color = baseColor
            local offset = {x = 0, y = 0, scale = 1}
        
            for _, effect in ipairs(self.effects) do
                if pos >= effect.startIndex and pos <= effect.endIndex then
                    local effectFunc = TextEffects[effect.type]
                    if effectFunc then
                        local effectColor, effectOffset = effectFunc(effect, char, pos, love.timer.getTime())
                        if effectColor then color = effectColor end
                        offset.x = offset.x + (effectOffset.x or 0)
                        offset.y = offset.y + (effectOffset.y or 0)
                        offset.scale = offset.scale * (effectOffset.scale or 1)
                    end
                end
            end

            local charTypeSpacing = isCJK(char) and self.letterSpacingCJK or self.letterSpacingLatin

            if x + self.font:getWidth(char) * offset.scale + charTypeSpacing > textX + textLimit then
                x = textX
                y = y + self.lineSpacing  -- 行间距
            end

            love.graphics.setColor(unpack(color))
            love.graphics.print(char, font1, x + offset.x, y + offset.y, 0, offset.scale, offset.scale)
            x = x + self.font:getWidth(char) * offset.scale + charTypeSpacing
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
                        local nextCharIndex = utf8.len(self.displayedText) + 1
                        local nextPos = utf8.offset(currentFullText, nextCharIndex)
                        local endPos = utf8.offset(currentFullText, nextCharIndex + 1) or #currentFullText + 1
                        self.displayedText = self.displayedText .. string.sub(currentFullText, nextPos, endPos - 1)
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
    self.currentExpression = currentDialogue.expression or "Default"
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

    
function LoveDialogue:destroy()
    if self.ninePatchImage and self.ninePatchImage:typeOf("Image") then
        self.ninePatchImage = nil
        --self.ninePatchImage:release()
    end
    self.font:release()
    self.nameFont:release()
end

function LoveDialogue:endDialogue()
    self.state = self.enableFadeOut and "fading_out" or "inactive"
    if not self.enableFadeOut then
        self.isActive = false
    end
    self:destroy()  -- 释放资源
end

function LoveDialogue:adjustLayout()
    -- 只在活跃状态下调整布局
    if self.state == "inactive" or self.state == "fading_out" then
        return
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    self.boxHeight = math.floor(windowHeight * 0.25)
    self.padding = math.floor(windowWidth * 0.02)
    self.font = love.graphics.newFont(math.floor(windowHeight * 0.025))
    self.nameFont = love.graphics.newFont(math.floor(windowHeight * 0.03))

    if self.boxtype then
        self:createNinePatchQuads()
    end
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