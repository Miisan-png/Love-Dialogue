local utf8 = require("utf8")
local LD_PATH = (...):match('(.-)[^%.]+$')

local ResourceManager = require(LD_PATH .. "ResourceManager")
local Parser = require(LD_PATH .. "LoveDialogueParser")
local Constants = require(LD_PATH .. "DialogueConstants")
local TextEffects = require(LD_PATH .. "TextEffects")
local ThemeParser = require(LD_PATH .. "ThemeParser")  
local PluginManager = require(LD_PATH .. "PluginManager")  
local character = require(LD_PATH .. "LoveCharacter")

local LoveDialogue = {}
local ninePatch = require(LD_PATH .. "9patch")

local nameFont = character.nameFont or love.graphics.newFont(12)
local textFont = character.font or love.graphics.newFont(12)

local function isCJK(char)
    local codepoint = utf8.codepoint(char)
    return (codepoint >= 0x4E00 and codepoint <= 0x9FFF) or   -- 基本汉字
           (codepoint >= 0x3400 and codepoint <= 0x4DBF) or   -- 扩展A
           (codepoint >= 0x20000 and codepoint <= 0x2A6DF)    -- 扩展B
end

function LoveDialogue:new(config)
    config = config or {} 
    
    -- Generate a unique ID for this dialogue instance
    local instanceId = tostring({}):match("table: (.*)")
    
    ---@class LoveDialogue
    ---@field characters table<string, LD_Character>
    local obj = {
        -- Add instance ID for resource tracking
        instanceId = instanceId,
        
        ninePatchPath = config.ninePatchPath,
        edgeWidth = config.edgeWidth or 10,
        edgeHeight = config.edgeHeight or 10,
        lines = {},
        characters = {},
        boxtype = config.useNinePatch or false,
        character_type = config.character_type or false,--0=原本的角色显示，1=竖直显示
        currentLine = 1,
        selectedChoice = 1,
        isActive = false,
        letterSpacingLatin = config.letterSpacingLatin or 4,  -- 西文字符间距
        letterSpacingCJK = config.letterSpacingCJK or 10,     -- 汉字字符间距
        lineSpacing = config.lineSpacing or 16,               -- 行间距
        boxColor = config.boxColor or {0.1, 0.1, 0.1, 0.9},
        textColor = config.textColor or {1, 1, 1, 1},
        nameColor = config.nameColor or {1, 0.8, 0.2, 1},
        padding = config.padding or 20,
        boxHeight = config.boxHeight or 150,
        portraitSize = config.portraitSize or 100,
        typingSpeed = config.typingSpeed or Constants.TYPING_SPEED,
        typewriterTimer = 0,
        displayedText = "",
        currentCharacter = "",
        boxOpacity = 0,
        fadeInDuration = config.fadeInDuration or Constants.FADE_IN_DURATION,
        fadeOutDuration = config.fadeOutDuration or Constants.FADE_OUT_DURATION,
        animationTimer = 0,
        state = "inactive",
        enableFadeIn = (config.enableFadeIn ~= nil) and config.enableFadeIn or true,
        enableFadeOut = (config.enableFadeOut ~= nil) and config.enableFadeOut or true,
        autoLayoutEnabled = (config.autoLayoutEnabled ~= nil) and config.autoLayoutEnabled or true,
        effects = {},
        currentBranch = nil,
        selectedBranchIndex = 1,
        waitTimer = 0,
        choiceMode = false,
        portraitEnabled = (config.portraitEnabled ~= nil) and config.portraitEnabled or true,
        ninePatchImage = nil,
        patch = nil,
        
        skipKey = config.skipKey or "f",
        textSpeeds = config.textSpeeds or {
            slow = 0.08,
            normal = 0.05,
            fast = 0.02
        },
        currentSpeedSetting = config.initialSpeedSetting or "normal",
        autoAdvance = (config.autoAdvance ~= nil) and config.autoAdvance or false,
        autoAdvanceDelay = config.autoAdvanceDelay or 2.0,
        autoAdvanceTimer = 0,
        
        -- Plugin storage
        plugins = {},
        pluginData = {},
    }
    
    -- Initialize typing speed from speed setting
    obj.typingSpeed = obj.textSpeeds[obj.currentSpeedSetting] or Constants.TYPING_SPEED
    
    setmetatable(obj, self)
    self.__index = self
    
    -- Create fonts using ResourceManager
    obj.font = ResourceManager:newFont(
        instanceId, 
        config.fontSize or Constants.DEFAULT_FONT_SIZE,
        nil,
        "main_font"
    )
    
    obj.nameFont = ResourceManager:newFont(
        instanceId, 
        config.nameFontSize or Constants.DEFAULT_NAME_FONT_SIZE,
        nil,
        "name_font"
    )
    
    obj.boxtype = config.useNinePatch or false
    obj.ninePatchPath = config.ninePatchPath

    if obj.boxtype and obj.ninePatchPath then
        obj.ninePatchImage = ResourceManager:newImage(instanceId, obj.ninePatchPath, "ninePatchImage")
        if obj.ninePatchImage then
            obj:createNinePatchQuads()
        else
            print("Warning: Failed to load 9-patch image")
            obj.boxtype = false -- Fall back to rectangle if image fails to load
        end
    end
    
    -- Initialize plugins if any are provided
    if config.plugins then
        for _, pluginName in ipairs(config.plugins) do
            obj:registerPlugin(pluginName)
        end
    end
    
    obj:triggerPluginEvent("onDialogueCreated", obj)

    return obj
end

-- Register a plugin by name
function LoveDialogue:registerPlugin(pluginName)
    local plugin = PluginManager:getPlugin(pluginName)
    if plugin then
        table.insert(self.plugins, plugin)
        self.pluginData[pluginName] = {}
        
        -- Initialize plugin if it has an init function
        if plugin.init then
            plugin.init(self, self.pluginData[pluginName])
        end
        
        return true
    end
    print("Warning: Plugin '" .. pluginName .. "' not found")
    return false
end

-- Trigger an event for all registered plugins
function LoveDialogue:triggerPluginEvent(eventName, ...)
    for _, plugin in ipairs(self.plugins) do
        if plugin[eventName] then
            plugin[eventName](self, self.pluginData[plugin.name], ...)
        end
    end
end

function LoveDialogue:createNinePatchQuads()
    -- Don't try to reload the image if it's missing
    if not self.ninePatchImage and self.ninePatchPath then
        self.ninePatchImage = ResourceManager:newImage(self.instanceId, self.ninePatchPath, "ninePatchImage")
        if not self.ninePatchImage then
            print("Warning: Failed to load 9-patch image")
            return
        end
    end
    
    -- Confirm image validity
    if self.ninePatchImage and self.ninePatchImage:typeOf("Image") then
        local edgeWidth = self.edgeWidth or 10
        local edgeHeight = self.edgeHeight or 10
        self.patch = ninePatch.loadSameEdge(self.ninePatchImage, edgeWidth, edgeHeight)
        
        -- Track quad resources if created
        if self.patch and self.patch.quads then
            for i, quad in ipairs(self.patch.quads) do
                ResourceManager:track(self.instanceId, "quads", quad, "ninePatchQuad_" .. i)
            end
        end
    else
        print("Warning: No valid 9-patch image available")
    end
end

function LoveDialogue:loadFromFile(filePath)
    self.lines, self.characters, self.scenes = Parser.parseFile(filePath)
    
    -- Assign instance ID to all characters for resource tracking
    for name, character in pairs(self.characters) do
        character.instanceId = self.instanceId
    end
    -- Let plugins know we've loaded a file
    self:triggerPluginEvent("onFileLoaded", filePath, self.lines, self.characters, self.scenes)
end

function LoveDialogue:start()
    self.isActive = true
    self.currentLine = 1
    self.state = self.enableFadeIn and "fading_in" or "active"
    self.animationTimer = 0
    self.boxOpacity = self.enableFadeIn and 0 or 1
    self:setCurrentDialogue()
    -- Let plugins know we're starting
    self:triggerPluginEvent("onDialogueStart")
end

function LoveDialogue:skipCurrentText()
    if self.isActive and self.state == "active" and not self.choiceMode then
        local currentFullText = self.lines[self.currentLine].text
        if self.displayedText ~= currentFullText then
            self.displayedText = currentFullText
            -- Let plugins know we skipped text (ooi)
            self:triggerPluginEvent("onTextSkipped")
            
            return true
        end
    end
    return false
end

function LoveDialogue:setTextSpeed(speedSetting)
    if self.textSpeeds[speedSetting] then
        self.currentSpeedSetting = speedSetting
        self.typingSpeed = self.textSpeeds[speedSetting]
        -- Let plugins know we changed speed
        self:triggerPluginEvent("onSpeedChanged", speedSetting, self.typingSpeed)
        
        return true
    end
    return false
end

function LoveDialogue:cycleTextSpeed()
    local speeds = {"slow", "normal", "fast"}
    local currentIndex = 1
    
    for i, speed in ipairs(speeds) do
        if speed == self.currentSpeedSetting then
            currentIndex = i
            break
        end
    end
    
    currentIndex = currentIndex % #speeds + 1
    self:setTextSpeed(speeds[currentIndex])
    return speeds[currentIndex]
end

function LoveDialogue:toggleAutoAdvance()
    self.autoAdvance = not self.autoAdvance
    self.autoAdvanceTimer = 0
    -- Let plugins know we toggled auto-advance
    self:triggerPluginEvent("onAutoAdvanceToggled", self.autoAdvance)
    
    return self.autoAdvance
end

function LoveDialogue:setAutoAdvanceDelay(seconds)
    self.autoAdvanceDelay = seconds
end

function LoveDialogue:update(dt)
    if not self.isActive then return end
    -- Let plugins modify update behavior if needed
    local modifiedDt = dt
    for _, plugin in ipairs(self.plugins) do
        if plugin.modifyDeltaTime then
            modifiedDt = plugin.modifyDeltaTime(self, self.pluginData[plugin.name], modifiedDt)
        end
    end
    
    -- Let plugins know we're updating
    self:triggerPluginEvent("onBeforeUpdate", modifiedDt)
    if self.state == "fading_in" then
        self.animationTimer = self.animationTimer + modifiedDt
        self.boxOpacity = math.min(self.animationTimer / self.fadeInDuration, 1)
        if self.animationTimer >= self.fadeInDuration then
            self.state = "active"
            self:triggerPluginEvent("onFadeInComplete")
        end
    elseif self.state == "active" then
        if not self.choiceMode then
            local currentFullText = self.lines[self.currentLine].text
            if self.displayedText ~= currentFullText then
                if self.waitTimer > 0 then
                    self.waitTimer = self.waitTimer - modifiedDt
                else
                    self.typewriterTimer = self.typewriterTimer + modifiedDt
                    if self.typewriterTimer >= self.typingSpeed then
                        self.typewriterTimer = 0
                        local nextCharIndex = utf8.len(self.displayedText) + 1
                        local nextPos = utf8.offset(currentFullText, nextCharIndex)
                        local endPos = utf8.offset(currentFullText, nextCharIndex + 1) or #currentFullText + 1
                        local newChar = string.sub(currentFullText, nextPos, endPos - 1)
                        self.displayedText = self.displayedText .. newChar
                        -- Let plugins know we added a character
                        self:triggerPluginEvent("onCharacterTyped", newChar, self.displayedText)
                    end
                end
            elseif self.autoAdvance then
                -- Text is fully displayed, start auto-advance timer
                self.autoAdvanceTimer = self.autoAdvanceTimer + modifiedDt
                if self.autoAdvanceTimer >= self.autoAdvanceDelay then
                    self.autoAdvanceTimer = 0
                    self:advance()
                end
            end
        end
    elseif self.state == "fading_out" then
        self.animationTimer = self.animationTimer + modifiedDt
        self.boxOpacity = 1 - math.min(self.animationTimer / self.fadeOutDuration, 1)
        if self.animationTimer >= self.fadeOutDuration then
            self.isActive = false
            self.state = "inactive"
            self:triggerPluginEvent("onFadeOutComplete")
            self:destroy() -- Clean up resources after fade out
        end
    end

    if self.autoLayoutEnabled then
        self:adjustLayout()
    end
    
    -- Let plugins know we finished updating
    self:triggerPluginEvent("onAfterUpdate", modifiedDt)
end

-- function LoveDialogue:draw()
--     if not self.isActive then return end
    
--     -- Let plugins modify drawing if needed
--     self:triggerPluginEvent("onBeforeDraw")
    
--     local windowWidth, windowHeight = love.graphics.getDimensions()
--     local boxWidth = windowWidth - 2 * self.padding

--     -- Draw character portrait for vertical mode
--     if self.character_type then
--         if self.portraitEnabled and self.currentCharacter and self.characters[self.currentCharacter]:hasPortrait() then
--             local portrait = self.characters[self.currentCharacter]:getExpression(self.currentExpression)
--             local sw, sh = portrait.quad:getTextureDimensions()
            
--             -- Calculate position
--             local portraitX = (windowWidth - sw)/2
--             local portraitY = windowHeight - sh

--             love.graphics.setColor(1, 1, 1, self.boxOpacity)
--             self.characters[self.currentCharacter]:draw(
--                 self.currentExpression,
--                 portraitX,
--                 portraitY,
--                 1,
--                 1
--             )
--         end
--     end

--     -- Draw dialogue box
--     if self.boxtype == false then
--         love.graphics.setColor(self.boxColor[1], self.boxColor[2], self.boxColor[3], self.boxColor[4] * self.boxOpacity)
--         love.graphics.rectangle("fill", self.padding, windowHeight - self.boxHeight - self.padding, boxWidth, self.boxHeight)
--     else
--         if self.patch then
--             -- Set color for 9-patch drawing
--             love.graphics.setColor(1, 1, 1, self.boxOpacity)
--             ninePatch.draw(self.patch, self.padding, windowHeight - self.boxHeight - self.padding, boxWidth, self.boxHeight)
--         end
--     end

--     local textX = self.padding * 2
--     local textY = windowHeight - self.boxHeight - self.padding + self.padding
--     local textLimit = boxWidth - (self.padding * 3)

--     -- Determine portrait visibility based on character_type
--     local hasPortrait = false
--     if not self.character_type then
--         hasPortrait = self.portraitEnabled and self.currentCharacter and self.characters[self.currentCharacter]:hasPortrait()
--     end

--     -- Draw horizontal portrait mode
--     if hasPortrait and not self.character_type then
--         local portrait = self.characters[self.currentCharacter]:getExpression(self.currentExpression)
--         local portraitX = self.padding * 2
--         local portraitY = windowHeight - self.boxHeight - self.padding + self.padding
--         local sw, sh = portrait.quad:getTextureDimensions()

--         love.graphics.setColor(0, 0, 0, self.boxOpacity * 0.5)
--         love.graphics.rectangle("fill", portraitX, portraitY, self.portraitSize, self.portraitSize)
        
--         love.graphics.setColor(1, 1, 1, self.boxOpacity)
--         self.characters[self.currentCharacter]:draw(
--             self.currentExpression, 
--             portraitX, 
--             portraitY, 
--             self.portraitSize / sw, 
--             self.portraitSize / sh
--         )
--         textX = self.padding * 3 + self.portraitSize
--         textLimit = boxWidth - self.portraitSize - (self.padding * 4)
--     end

--     -- Draw character name if present
--     if self.currentCharacter and self.currentCharacter ~= "" then
--         -- love.graphics.setFont(self.nameFont)
--         local nameColor = self.characters[self.currentCharacter].nameColor or self.nameColor
--         love.graphics.setColor(nameColor.r or nameColor[1], nameColor.g or nameColor[2], 
--                              nameColor.b or nameColor[3], self.boxOpacity)
--         love.graphics.print(self.currentCharacter,nameFont, textX, textY)
--         textY = textY + self.nameFont:getHeight() + 5
--     end

--     -- Set font for dialogue text
--     -- love.graphics.setFont(self.font)
    
--     -- Draw choices or text based on mode
--     if self.choiceMode then
--         for i, choice in ipairs(self.lines[self.currentLine].choices) do
--             local prefix = (i == self.selectedChoice) and "> " or "  "
--             local x = textX + self.font:getWidth(prefix)
--             local y = textY + (i - 1) * self.lineSpacing
            
--             local choiceColor = (i == self.selectedChoice) and {1, 1, 0, self.boxOpacity} or {1, 1, 1, self.boxOpacity}
--             love.graphics.setColor(unpack(choiceColor))
--             love.graphics.print(prefix, textX, y)
            
--             if choice.parsedText then
--                 self:drawFormattedText(choice.parsedText, x, y, choiceColor, choice.effects)
--             end
--         end
--     else
--         -- Draw regular text with formatting and effects
--         self:drawFormattedText(self.displayedText, textX, textY, 
--             {self.textColor[1], self.textColor[2], self.textColor[3], self.textColor[4] * self.boxOpacity},
--             self.effects, textLimit)
--     end
    
--     -- Draw auto-advance indicator if enabled
--     if self.autoAdvance and self.state == "active" and self.displayedText == self.lines[self.currentLine].text then
--         local progress = self.autoAdvanceTimer / self.autoAdvanceDelay
--         love.graphics.setColor(1, 1, 1, self.boxOpacity * 0.7)
--         love.graphics.rectangle("fill", 
--             boxWidth - 40, 
--             windowHeight - self.padding - 10, 
--             30 * progress, 
--             5)
--     end
    
--     self:triggerPluginEvent("onAfterDraw")
-- end

function LoveDialogue:draw()
    if not self.isActive then return end
    
    -- Let plugins modify drawing if needed
    self:triggerPluginEvent("onBeforeDraw")
    
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boxWidth = windowWidth - 2 * self.padding

    -- Draw character portrait for vertical mode
    if self.character_type then
        if self.portraitEnabled and self.currentCharacter and self.characters[self.currentCharacter]:hasPortrait() then
            local portrait = self.characters[self.currentCharacter]:getExpression(self.currentExpression)
            local sw, sh = portrait.quad:getTextureDimensions()
            
            -- Calculate position
            local portraitX = (windowWidth - sw)/2
            local portraitY = windowHeight - sh

            love.graphics.setColor(1, 1, 1, self.boxOpacity)
            self.characters[self.currentCharacter]:draw(
                self.currentExpression,
                portraitX,
                portraitY,
                1,
                1
            )
        end
    end

    -- Draw dialogue box
    if self.boxtype == false then
        love.graphics.setColor(self.boxColor[1], self.boxColor[2], self.boxColor[3], self.boxColor[4] * self.boxOpacity)
        love.graphics.rectangle("fill", self.padding, windowHeight - self.boxHeight - self.padding, boxWidth, self.boxHeight)
    else
        if self.patch then
            -- Set color for 9-patch drawing
            love.graphics.setColor(1, 1, 1, self.boxOpacity)
            ninePatch.draw(self.patch, self.padding, windowHeight - self.boxHeight - self.padding, boxWidth, self.boxHeight)
        end
    end

    local textX = self.padding * 2
    local textY = windowHeight - self.boxHeight - self.padding + self.padding
    local textLimit = boxWidth - (self.padding * 3)

    -- Determine portrait visibility based on character_type
    local hasPortrait = false
    if not self.character_type then
        hasPortrait = self.portraitEnabled and self.currentCharacter and self.characters[self.currentCharacter]:hasPortrait()
    end

    -- Draw horizontal portrait mode
    if hasPortrait and not self.character_type then
        local portrait = self.characters[self.currentCharacter]:getExpression(self.currentExpression)
        local portraitX = self.padding * 2
        local portraitY = windowHeight - self.boxHeight - self.padding + self.padding
        local sw, sh = portrait.quad:getTextureDimensions()

        love.graphics.setColor(0, 0, 0, self.boxOpacity * 0.5)
        love.graphics.rectangle("fill", portraitX, portraitY, self.portraitSize, self.portraitSize)
        
        love.graphics.setColor(1, 1, 1, self.boxOpacity)
        self.characters[self.currentCharacter]:draw(
            self.currentExpression, 
            portraitX, 
            portraitY, 
            self.portraitSize / sw, 
            self.portraitSize / sh
        )
        textX = self.padding * 3 + self.portraitSize
        textLimit = boxWidth - self.portraitSize - (self.padding * 4)
    end

    -- Draw character name if present
    if self.currentCharacter and self.currentCharacter ~= "" then
        local nameFont = self.characters[self.currentCharacter].nameFont or self.nameFont or love.graphics.newFont(12)
        local nameColor = self.characters[self.currentCharacter].nameColor or self.nameColor
        love.graphics.setColor(nameColor.r or nameColor[1], nameColor.g or nameColor[2], 
                             nameColor.b or nameColor[3], self.boxOpacity)
        love.graphics.print(self.currentCharacter, nameFont, textX, textY)
        textY = textY + nameFont:getHeight() + 5
    end

    -- Draw choices or text based on mode
    local textFont = self.currentCharacter and self.characters[self.currentCharacter].font or self.font or love.graphics.newFont(12)
    if self.choiceMode then
        for i, choice in ipairs(self.lines[self.currentLine].choices) do
            local prefix = (i == self.selectedChoice) and "> " or "  "
            local x = textX + textFont:getWidth(prefix)
            local y = textY + (i - 1) * self.lineSpacing
            
            local choiceColor = (i == self.selectedChoice) and {1, 1, 0, self.boxOpacity} or {1, 1, 1, self.boxOpacity}
            love.graphics.setColor(unpack(choiceColor))
            love.graphics.print(prefix, textFont, textX, y)
            
            if choice.parsedText then
                self:drawFormattedText(choice.parsedText, textFont, x, y, choiceColor, choice.effects)
            end
        end
    else
        -- Draw regular text with formatting and effects
        self:drawFormattedText(self.displayedText, textFont, textX, textY, 
            {self.textColor[1], self.textColor[2], self.textColor[3], self.textColor[4] * self.boxOpacity},
            self.effects, textLimit)
    end
    
    -- Draw auto-advance indicator if enabled
    if self.autoAdvance and self.state == "active" and self.displayedText == self.lines[self.currentLine].text then
        local progress = self.autoAdvanceTimer / self.autoAdvanceDelay
        love.graphics.setColor(1, 1, 1, self.boxOpacity * 0.7)
        love.graphics.rectangle("fill", 
            boxWidth - 40, 
            windowHeight - self.padding - 10, 
            30 * progress, 
            5)
    end
    
    self:triggerPluginEvent("onAfterDraw")
end

function LoveDialogue:drawFormattedText(text, font, startX, startY, baseColor, effects, textLimit)
    local x = startX
    local y = startY
    
    textLimit = textLimit or math.huge
    
    for pos, char in utf8.codes(text) do
        local char = utf8.char(char)
        local color = {baseColor[1], baseColor[2], baseColor[3], baseColor[4]}
        local offset = {x = 0, y = 0, scale = 1}
    
        if effects then
            for _, effect in ipairs(effects) do
                if pos == effect.startIndex and effect.type == "sound" then
                    local sound = ResourceManager:newSound(self.instanceId, effect.content, "sound_"..effect.content)
                    if sound then
                        sound:play()
                    end
                elseif pos >= effect.startIndex and pos <= effect.endIndex then
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
        end

        local charTypeSpacing = isCJK(char) and self.letterSpacingCJK or self.letterSpacingLatin
        
        -- Handle text wrapping if a limit is specified
        if textLimit and x + font:getWidth(char) * offset.scale + charTypeSpacing > startX + textLimit then
            x = startX
            y = y + self.lineSpacing
        end

        -- Draw the character with effects applied
        love.graphics.setColor(unpack(color))
        love.graphics.print(char, font, x + offset.x, y + offset.y, 0, offset.scale, offset.scale)
        x = x + font:getWidth(char) * offset.scale + charTypeSpacing
    end
end

-- function LoveDialogue:drawFormattedText(text, startX, startY, baseColor, effects, textLimit)
--     local x = startX
--     local y = startY
    
--     textLimit = textLimit or math.huge
    
--     for pos, char in utf8.codes(text) do
--         local char = utf8.char(char)
--         local color = {baseColor[1], baseColor[2], baseColor[3], baseColor[4]}
--         local offset = {x = 0, y = 0, scale = 1}
    
--         if effects then
--             for _, effect in ipairs(effects) do
--                 if pos >= effect.startIndex and pos <= effect.endIndex then
--                     local effectFunc = TextEffects[effect.type]
--                     if effectFunc then
--                         local effectColor, effectOffset = effectFunc(effect, char, pos, love.timer.getTime())
--                         if effectColor then color = effectColor end
--                         offset.x = offset.x + (effectOffset.x or 0)
--                         offset.y = offset.y + (effectOffset.y or 0)
--                         offset.scale = offset.scale * (effectOffset.scale or 1)
--                     end
--                 end
--             end
--         end

--         local charTypeSpacing = isCJK(char) and self.letterSpacingCJK or self.letterSpacingLatin
        
--         -- Handle text wrapping if a limit is specified
--         if textLimit and x + self.font:getWidth(char) * offset.scale + charTypeSpacing > startX + textLimit then
--             x = startX
--             y = y + self.lineSpacing
--         end

--         -- Draw the character with effects applied
--         love.graphics.setColor(unpack(color))
--         love.graphics.print(char,textFont, x + offset.x, y + offset.y, 0, offset.scale, offset.scale)
--         x = x + self.font:getWidth(char) * offset.scale + charTypeSpacing
--     end
-- end

function LoveDialogue:advance()
    if self.state ~= "active" then
        if self.state == "fading_in" then
            self.state = "active"
            self.boxOpacity = 1
        end
        return
    end

    self:triggerPluginEvent("onBeforeAdvance")

    if self.choiceMode then
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

        self:triggerPluginEvent("onChoiceSelected", self.selectedChoice, selectedChoice)
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
            self:triggerPluginEvent("onTextSkipped")
        else
            if self.lines[self.currentLine].isEnd then
                self:endDialogue()
            else
                self.currentLine = self.currentLine + 1
                self:setCurrentDialogue()
            end
        end
    end
    self.autoAdvanceTimer = 0
    self:triggerPluginEvent("onAfterAdvance")
end

function LoveDialogue:setCurrentDialogue()
    local currentDialogue = self.lines[self.currentLine]
    if not currentDialogue then
        print("Warning: No dialogue found for line", self.currentLine)
        self:endDialogue()
        return
    end

    self:triggerPluginEvent("onBeforeDialogueSet", currentDialogue)

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
    self.autoAdvanceTimer = 0
    self:triggerPluginEvent("onAfterDialogueSet", currentDialogue)
end

function LoveDialogue:keypressed(key)
    if not self.isActive then return end
    local keyHandled = false
    for _, plugin in ipairs(self.plugins) do
        if plugin.handleKeyPress then
            keyHandled = plugin.handleKeyPress(self, self.pluginData[plugin.name], key)
            if keyHandled then break end
        end
    end
    
    if keyHandled then return end
    if key == self.skipKey then
        if self:skipCurrentText() then
            return
        end
    elseif key == "t" then
        local newSpeed = self:cycleTextSpeed()
        print("Text speed changed to:", newSpeed)
        return
    elseif key == "a" then
        local autoStatus = self:toggleAutoAdvance()
        print("Auto-advance " .. (autoStatus and "enabled" or "disabled"))
        return
    end
    if self.choiceMode then
        if key == "up" then
            self.selectedChoice = math.max(1, self.selectedChoice - 1)
            self:triggerPluginEvent("onChoiceNavigation", "up", self.selectedChoice)
        elseif key == "down" then
            self.selectedChoice = math.min(#self.lines[self.currentLine].choices, self.selectedChoice + 1)
            self:triggerPluginEvent("onChoiceNavigation", "down", self.selectedChoice)
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
    self:triggerPluginEvent("onBeforeDestroy")
    ResourceManager:releaseInstance(self.instanceId)
    self.ninePatchImage = nil
    self.patch = nil
    self.font = nil
    self.nameFont = nil
    
    for _, plugin in ipairs(self.plugins) do
        if plugin.cleanup then
            plugin.cleanup(self, self.pluginData[plugin.name])
        end
        self.pluginData[plugin.name] = nil
    end
    
    self.plugins = {}
end

function LoveDialogue:endDialogue()
    self:triggerPluginEvent("onDialogueEnd")
    
    self.state = self.enableFadeOut and "fading_out" or "inactive"
    if not self.enableFadeOut then
        self.isActive = false
        self:destroy()  -- Clean up resources immediately if no fade-out
    end
end

function LoveDialogue:adjustLayout()
    if self.state == "inactive" or self.state == "fading_out" then
        return
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    self.boxHeight = math.floor(windowHeight * 0.25)
    self.padding = math.floor(windowWidth * 0.02)
    
    self.font = ResourceManager:newFont(
        self.instanceId,
        math.floor(windowHeight * 0.025),
        nil,
        "mainFont"
    )
    
    self.nameFont = ResourceManager:newFont(
        self.instanceId,
        math.floor(windowHeight * 0.03),
        nil,
        "nameFont"
    )

    if self.boxtype then
        self:createNinePatchQuads()
    end
    
    self:triggerPluginEvent("onLayoutAdjusted", windowWidth, windowHeight)
end

function LoveDialogue:loadTheme(themePath)
    local theme = ThemeParser.parseTheme(themePath)
    if theme then
        ThemeParser.applyTheme(self, theme)
        self:triggerPluginEvent("onThemeLoaded", theme)
        return true
    end
    return false
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