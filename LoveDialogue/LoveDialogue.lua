local MODULE_PATH = (...):match('(.-)[^%.]+$')

local ResourceManager = require(MODULE_PATH .. "ResourceManager")
local Parser = require(MODULE_PATH .. "LoveDialogueParser")
local Constants = require(MODULE_PATH .. "DialogueConstants")
local TextEffects = require(MODULE_PATH .. "TextEffects")
local ThemeParser = require(MODULE_PATH .. "ThemeParser")
local PluginManager = require(MODULE_PATH .. "PluginManager")
local ninePatch = require(MODULE_PATH .. "9patch")
local Logic = require(MODULE_PATH .. "Logic")
local utf8 = require("utf8")

local LoveDialogue = {}
LoveDialogue.__index = LoveDialogue

local function isCJK(char)
    local cp = utf8.codepoint(char)
    return (cp >= 0x4E00 and cp <= 0x9FFF) or
           (cp >= 0x3400 and cp <= 0x4DBF) or
           (cp >= 0x20000 and cp <= 0x2A6DF)
end

function LoveDialogue.new(config)
    config = config or {}
    local self = setmetatable({}, LoveDialogue)
    
    self.instanceId = tostring(self):sub(8)
    
    self.config = {
        ninePatchPath = config.ninePatchPath,
        edgeWidth = config.edgeWidth or 10,
        edgeHeight = config.edgeHeight or 10,
        useNinePatch = config.useNinePatch or false,
        characterType = config.character_type or 0,
        letterSpacingLatin = config.letterSpacingLatin or 4,
        letterSpacingCJK = config.letterSpacingCJK or 10,
        lineSpacing = config.lineSpacing or 16,
        boxColor = config.boxColor or {0.1, 0.1, 0.1, 0.9},
        textColor = config.textColor or {1, 1, 1, 1},
        nameColor = config.nameColor or {1, 0.8, 0.2, 1},
        padding = config.padding or 20,
        boxHeight = config.boxHeight or 150,
        portraitSize = config.portraitSize or 100,
        baseTypingSpeed = config.typingSpeed or Constants.TYPING_SPEED,
        fadeInDuration = config.fadeInDuration or Constants.FADE_IN_DURATION,
        fadeOutDuration = config.fadeOutDuration or Constants.FADE_OUT_DURATION,
        enableFadeIn = config.enableFadeIn ~= false,
        enableFadeOut = config.enableFadeOut ~= false,
        autoLayout = config.autoLayoutEnabled ~= false,
        portraitEnabled = config.portraitEnabled ~= false,
        skipKey = config.skipKey or "f",
        controls = config.controls or {
            next = {"return", "space"},
            up = {"up"},
            down = {"down"},
            toggleAuto = {"a"},
            toggleSpeed = {"t"}
        },
        autoAdvanceDelay = config.autoAdvanceDelay or 2.0,
        speeds = config.textSpeeds or { slow = 0.08, normal = 0.05, fast = 0.02 },
        initialSpeed = config.initialSpeedSetting or "normal",
        pluginData = config.pluginData or {},
        initialVariables = config.initialVariables or {}
    }

    self.state = {
        lines = {},
        characters = {},
        scenes = {},
        variables = {}, -- Stores runtime variables
        currentLineIndex = 1,
        isActive = false,
        status = "inactive", 
        typewriterTimer = 0,
        displayedText = "",
        currentCharacter = "",
        boxOpacity = 0,
        animationTimer = 0,
        effects = {},
        waitTimer = 0,
        choiceMode = false,
        selectedChoice = 1,
        activeChoices = {}, -- Subset of choices that passed condition check
        currentExpression = "Default",
        autoAdvance = config.autoAdvance or false,
        autoAdvanceTimer = 0,
        typingSpeed = self.config.speeds[self.config.initialSpeed] or 0.05,
        currentSpeedSetting = self.config.initialSpeed
    }

    -- Deep copy initial variables
    for k,v in pairs(self.config.initialVariables) do
        self.state.variables[k] = v
    end

    self.resources = {
        font = ResourceManager:getFont(self.instanceId, config.fontSize or Constants.DEFAULT_FONT_SIZE, nil, "main_font"),
        nameFont = ResourceManager:getFont(self.instanceId, config.nameFontSize or Constants.DEFAULT_NAME_FONT_SIZE, nil, "name_font"),
        ninePatch = nil,
        patch = nil
    }

    if self.config.useNinePatch and self.config.ninePatchPath then
        self:loadNinePatch()
    end

    self.plugins = {}
    if config.plugins then
        for _, name in ipairs(config.plugins) do
            self:registerPlugin(name)
        end
    end

    self:triggerPluginEvent("onDialogueCreated")
    return self
end

function LoveDialogue:loadNinePatch()
    local img = ResourceManager:getImage(self.instanceId, self.config.ninePatchPath)
    if img then
        self.resources.ninePatch = img
        self.resources.patch = ninePatch.loadSameEdge(img, self.config.edgeWidth, self.config.edgeHeight)
    else
        self.config.useNinePatch = false
    end
end

function LoveDialogue:registerPlugin(name)
    local plugin = PluginManager:getPlugin(name)
    if plugin then
        table.insert(self.plugins, plugin)
        self.config.pluginData[name] = self.config.pluginData[name] or {}
        if plugin.init then plugin.init(self, self.config.pluginData[name]) end
    end
end

function LoveDialogue:triggerPluginEvent(event, ...)
    for _, plugin in ipairs(self.plugins) do
        if plugin[event] then
            plugin[event](self, self.config.pluginData[plugin.name], ...)
        end
    end
end

function LoveDialogue:loadFromFile(path)
    local lines, chars, scenes = Parser.parseFile(path, self.instanceId)
    self.state.lines = lines
    self.state.characters = chars
    self.state.scenes = scenes
    self:triggerPluginEvent("onFileLoaded", path, lines, chars, scenes)
end

function LoveDialogue:start()
    self.state.isActive = true
    self.state.currentLineIndex = 1
    self.state.status = self.config.enableFadeIn and "fading_in" or "active"
    self.state.animationTimer = 0
    self.state.boxOpacity = self.config.enableFadeIn and 0 or 1
    self:processCurrentLine() -- Changed from updateCurrentDialogue to handle logic skipping
    self:triggerPluginEvent("onDialogueStart")
end

-- Replaces updateCurrentDialogue. Recursive/Looping to skip non-dialogue lines.
function LoveDialogue:processCurrentLine()
    local line = self.state.lines[self.state.currentLineIndex]
    
    if not line then 
        return self:endDialogue() 
    end

    -- Handle Logic Lines
    if line.type == "command" then
        Logic.execute(line.statement, self.state.variables)
        self.state.currentLineIndex = self.state.currentLineIndex + 1
        return self:processCurrentLine() -- Recursively execute next line immediately
        
    elseif line.type == "block_if" then
        local result = Logic.evaluate(line.condition, self.state.variables)
        if result then
            -- True: Just continue to next line
            self.state.currentLineIndex = self.state.currentLineIndex + 1
            return self:processCurrentLine()
        else
            -- False: Skip to ELSE or ENDIF
            self:skipToBlockEnd()
            return self:processCurrentLine()
        end
        
    elseif line.type == "block_else" then
        -- If we hit an ELSE naturally, it means the IF block before it executed.
        -- So we must skip this ELSE block now.
        self:skipToBlockEnd()
        return self:processCurrentLine()
        
    elseif line.type == "block_endif" then
        -- Just a marker, pass through
        self.state.currentLineIndex = self.state.currentLineIndex + 1
        return self:processCurrentLine()
        
    -- NEW: Handle Signals
    elseif line.type == "signal" then
        self:triggerPluginEvent("onSignal", line.name, line.args)
        -- Also allow main app to hook via simple callback if assigned
        if self.onSignal then self.onSignal(line.name, line.args) end
        
        self.state.currentLineIndex = self.state.currentLineIndex + 1
        return self:processCurrentLine() -- Continue immediately
    end

    -- If we get here, it's a "dialogue" line
    self:setDialogueState(line)
end

function LoveDialogue:skipToBlockEnd()
    local depth = 1
    while depth > 0 do
        self.state.currentLineIndex = self.state.currentLineIndex + 1
        local line = self.state.lines[self.state.currentLineIndex]
        if not line then break end
        
        if line.type == "block_if" then
            depth = depth + 1
        elseif line.type == "block_endif" then
            depth = depth - 1
        elseif line.type == "block_else" and depth == 1 then
            -- Found the matching else for the current if
            -- We stop here (pointing AT the else), so next process call steps inside the else block
            -- wait, if we are skipping to block end because IF failed, we WANT to enter ELSE.
            -- if we are skipping because IF succeeded, we want to skip ELSE.
            
            -- Wait, this function is generic "skip". 
            -- Case 1: IF failed -> Find ELSE or ENDIF. If find ELSE, stop there (next step enters it). If ENDIF, stop there.
            -- Case 2: IF succeeded -> Hit ELSE -> Find ENDIF.
            
            -- Let's differentiate.
            -- Actually, simpler logic:
            -- If we are scanning for an ELSE/ENDIF (because IF false): stop at depth 1 ELSE or ENDIF.
            -- If we are scanning for ENDIF (because we finished IF true block): ignore ELSE, stop at depth 1 ENDIF.
            
            -- This function is too simple. Let's rely on the caller or make it smarter.
            -- But for now, let's assume we simply scan for the "next logical block".
            
            -- Refined logic for scanning:
            -- When skipping a failed IF: We want to land on the line AFTER 'else' or AFTER 'endif'.
            -- But processCurrentLine increments index.
            
            -- Let's just consume the ELSE tag if we find it.
            self.state.currentLineIndex = self.state.currentLineIndex + 1 -- Skip the ELSE tag itself
            return
        end
    end
end

-- Better logic skipping implementation
function LoveDialogue:skipToBlockEnd()
    local startLine = self.state.lines[self.state.currentLineIndex]
    -- We are at [if] (failed) OR [else] (finished if block)
    -- We need to find the matching [else] or [endif]
    
    local depth = 1
    while true do
        self.state.currentLineIndex = self.state.currentLineIndex + 1
        local line = self.state.lines[self.state.currentLineIndex]
        if not line then break end
        
        if line.type == "block_if" then
            depth = depth + 1
        elseif line.type == "block_endif" then
            depth = depth - 1
            if depth == 0 then
                -- Found the end. We are now AT [endif]. 
                -- We should execute the line AFTER this.
                self.state.currentLineIndex = self.state.currentLineIndex + 1
                return
            end
        elseif line.type == "block_else" then
            if depth == 1 then
                -- Found an else at our level. 
                -- If we were skipping the IF block (startLine was IF), we Enter this else.
                -- If we were skipping the ELSE block (startLine was ELSE), we continue skipping.
                
                -- Wait, we can't know "why" we are skipping just from state.
                -- Let's implement specific skippers.
            end
        end
    end
end

-- Helper to find the matching ELSE or ENDIF for the current IF (failed condition)
function LoveDialogue:skipToBlockEnd()
    -- We are currently AT the line that triggered the skip (e.g. [if] or [else])
    local depth = 0
    local targetElse = (self.state.lines[self.state.currentLineIndex].type == "block_if")
    
    while true do
        self.state.currentLineIndex = self.state.currentLineIndex + 1
        local line = self.state.lines[self.state.currentLineIndex]
        if not line then break end
        
        if line.type == "block_if" then
            depth = depth + 1
        elseif line.type == "block_endif" then
            if depth == 0 then
                -- Found the end of our block
                self.state.currentLineIndex = self.state.currentLineIndex + 1
                return
            end
            depth = depth - 1
        elseif line.type == "block_else" then
            if depth == 0 and targetElse then
                -- We were looking for an else (IF failed), and we found it.
                -- Consume the else line and start executing body
                self.state.currentLineIndex = self.state.currentLineIndex + 1
                return
            end
        end
    end
end

function LoveDialogue:setDialogueState(line)
    self:triggerPluginEvent("onBeforeDialogueSet", line)

    self.state.currentCharacter = line.character or ""
    self.state.currentExpression = line.expression or "Default"
    
    -- Interpolate text
    local finalText = Logic.interpolate(line.rawText, self.state.variables)
    
    -- Re-parse effects if interpolation changed the string length/content significantly?
    -- Actually, if we interpolate, existing effect indices might break if the variable length != placeholder length.
    -- Simple fix: Re-parse tags completely after interpolation.
    -- But rawText in parser has tags stripped. We need raw-raw text.
    -- Parser stores `rawText` as "Text with {tags}".
    -- Logic.interpolate will replace `${var}` inside that.
    -- Then we need to parse tags again.
    local pText, eff = Parser.parseTextWithTags(finalText)
    
    self.state.displayedText = ""
    self.state.fullText = pText -- Stored for typewriter
    self.state.effects = {}
    
    -- Re-build effects list from new parse
    if eff then
        for _, e in ipairs(eff) do
            table.insert(self.state.effects, {
                type = e.type, content = e.content,
                startIndex = e.startIndex, endIndex = e.endIndex,
                timer = 0
            })
        end
    end

    self.state.typewriterTimer = 0
    self.state.waitTimer = 0
    
    -- Choice Logic
    self.state.activeChoices = {}
    if line.choices and #line.choices > 0 then
        for _, c in ipairs(line.choices) do
            -- Check condition
            local allowed = true
            if c.condition then
                allowed = Logic.evaluate(c.condition, self.state.variables)
            end
            
            if allowed then
                -- Interpolate choice text too
                local choiceTxt = Logic.interpolate(c.text, self.state.variables)
                local cpText, ceff = Parser.parseTextWithTags(choiceTxt)
                
                -- Create a runtime choice object
                table.insert(self.state.activeChoices, {
                    text = choiceTxt,
                    parsedText = cpText,
                    effects = ceff,
                    target = c.target
                })
            end
        end
    end
    
    self.state.choiceMode = (#self.state.activeChoices > 0)
    if self.state.choiceMode then
        self.state.displayedText = self.state.fullText
        self.state.selectedChoice = 1
    end

    self.state.autoAdvanceTimer = 0
    self:triggerPluginEvent("onAfterDialogueSet", line)
end

function LoveDialogue:update(dt)
    if not self.state.isActive then return end
    
    for _, p in ipairs(self.plugins) do
        if p.modifyDeltaTime then dt = p.modifyDeltaTime(self, self.config.pluginData[p.name], dt) end
    end

    self:triggerPluginEvent("onBeforeUpdate", dt)

    if self.state.status == "fading_in" then
        self.state.animationTimer = self.state.animationTimer + dt
        self.state.boxOpacity = math.min(self.state.animationTimer / self.config.fadeInDuration, 1)
        if self.state.animationTimer >= self.config.fadeInDuration then
            self.state.status = "active"
            self:triggerPluginEvent("onFadeInComplete")
        end
    elseif self.state.status == "fading_out" then
        self.state.animationTimer = self.state.animationTimer + dt
        self.state.boxOpacity = 1 - math.min(self.state.animationTimer / self.config.fadeOutDuration, 1)
        if self.state.animationTimer >= self.config.fadeOutDuration then
            self.state.isActive = false
            self.state.status = "inactive"
            self:triggerPluginEvent("onFadeOutComplete")
            self:destroy()
        end
    elseif self.state.status == "active" and not self.state.choiceMode then
        self:handleTypewriter(dt)
    end

    if self.config.autoLayout then self:adjustLayout() end
    self:triggerPluginEvent("onAfterUpdate", dt)
end

function LoveDialogue:handleTypewriter(dt)
    local fullText = self.state.fullText
    if self.state.displayedText ~= fullText then
        if self.state.waitTimer > 0 then
            self.state.waitTimer = self.state.waitTimer - dt
        else
            self.state.typewriterTimer = self.state.typewriterTimer + dt
            if self.state.typewriterTimer >= self.state.typingSpeed then
                self.state.typewriterTimer = 0
                local p = utf8.offset(fullText, utf8.len(self.state.displayedText) + 2)
                self.state.displayedText = fullText:sub(1, (p or #fullText + 1) - 1)
                self:triggerPluginEvent("onCharacterTyped", self.state.displayedText)
            end
        end
    elseif self.state.autoAdvance then
        self.state.autoAdvanceTimer = self.state.autoAdvanceTimer + dt
        if self.state.autoAdvanceTimer >= self.config.autoAdvanceDelay then
            self:advance()
        end
    else
        self:triggerPluginEvent("onUtteranceEnd", self.state.displayedText)
    end
end

function LoveDialogue:draw()
    if not self.state.isActive then return end
    self:triggerPluginEvent("onBeforeDraw")

    local w, h = love.graphics.getDimensions()
    local boxW = w - 2 * self.config.padding
    local boxH = self.config.boxHeight
    local opacity = self.state.boxOpacity
    
    if self.config.characterType == 1 then self:drawVerticalPortrait(w, h, opacity) end

    if not self.config.useNinePatch then
        love.graphics.setColor(self.config.boxColor[1], self.config.boxColor[2], self.config.boxColor[3], self.config.boxColor[4] * opacity)
        love.graphics.rectangle("fill", self.config.padding, h - boxH - self.config.padding, boxW, boxH)
    elseif self.resources.patch then
        love.graphics.setColor(1, 1, 1, opacity)
        ninePatch.draw(self.resources.patch, self.config.padding, h - boxH - self.config.padding, boxW, boxH)
    end

    local textX = self.config.padding * 2
    local textY = h - boxH
    local textLimit = boxW - self.config.padding * 2

    if self.config.characterType == 0 then
        local pX, pW = self:drawHorizontalPortrait(h, boxH, opacity)
        if pW > 0 then
            textX = pX + pW + self.config.padding
            textLimit = textLimit - pW - self.config.padding
        end
    end

    self:drawName(textX, textY, opacity)
    if self.state.currentCharacter ~= "" then
        textY = textY + self.resources.nameFont:getHeight() + 5
    end

    love.graphics.setFont(self.resources.font)
    if self.state.choiceMode then
        self:drawChoices(textX, textY, opacity)
    else
        self:drawFormattedText(self.state.displayedText, textX, textY, self.config.textColor, self.state.effects, textLimit, opacity)
    end

    if self.state.autoAdvance and self.state.status == "active" and self.state.displayedText == self.state.fullText then
        love.graphics.setColor(1, 1, 1, opacity * 0.7)
        love.graphics.rectangle("fill", boxW - 40, h - self.config.padding - 10, 30 * (self.state.autoAdvanceTimer / self.config.autoAdvanceDelay), 5)
    end

    self:triggerPluginEvent("onAfterDraw")
end

function LoveDialogue:drawVerticalPortrait(w, h, opacity)
    if not self.config.portraitEnabled then return end
    local char = self.state.characters[self.state.currentCharacter]
    if char and char:hasPortrait() then
        love.graphics.setColor(1, 1, 1, opacity)
        local pX = (w - 100) / 2 -- Center approximation, real implementation depends on portrait size
        char:draw(self.state.currentExpression, pX, h - 300, 1, 1) -- Adjust Y as needed
    end
end

function LoveDialogue:drawHorizontalPortrait(h, boxH, opacity)
    if not self.config.portraitEnabled then return 0, 0 end
    local char = self.state.characters[self.state.currentCharacter]
    if char and char:hasPortrait() then
        local pSize = self.config.portraitSize
        local x = self.config.padding * 2
        local y = h - boxH 
        
        love.graphics.setColor(0, 0, 0, opacity * 0.5)
        love.graphics.rectangle("fill", x, y, pSize, pSize)
        love.graphics.setColor(1, 1, 1, opacity)
        char:draw(self.state.currentExpression, x, y, pSize, pSize)
        return x, pSize
    end
    return 0, 0
end

function LoveDialogue:drawName(x, y, opacity)
    if self.state.currentCharacter == "" then return end
    local char = self.state.characters[self.state.currentCharacter]
    local c = char and char.nameColor or self.config.nameColor
    love.graphics.setFont(self.resources.nameFont)
    love.graphics.setColor(c[1] or c.r, c[2] or c.g, c[3] or c.b, opacity)
    love.graphics.print(self.state.currentCharacter, x, y)
end

function LoveDialogue:drawChoices(x, y, opacity)
    -- Iterate over ACTIVE choices, not all choices
    for i, choice in ipairs(self.state.activeChoices) do
        local isSel = (i == self.state.selectedChoice)
        local prefix = isSel and "> " or "  "
        local cy = y + (i - 1) * self.config.lineSpacing
        local col = isSel and {1, 1, 0, opacity} or {1, 1, 1, opacity}
        
        love.graphics.setColor(unpack(col))
        love.graphics.print(prefix, x, cy)
        
        if choice.parsedText then
            self:drawFormattedText(choice.parsedText, x + self.resources.font:getWidth(prefix), cy, col, choice.effects, math.huge, opacity)
        end
    end
end

function LoveDialogue:drawFormattedText(text, x, y, color, effects, limit, opacity)
    local startX = x
    local curX, curY = x, y
    local col = {color[1], color[2], color[3], color[4] * opacity}
    
    for pos, char in utf8.codes(text) do
        local c = utf8.char(char)
        local dx, dy, s = 0, 0, 1
        local ec = col
        
        if effects then
            local t = love.timer.getTime()
            for _, e in ipairs(effects) do
                if pos >= e.startIndex and pos <= e.endIndex then
                    local fn = TextEffects[e.type]
                    if fn then
                        local nc, off = fn(e, c, pos, t)
                        if nc then ec = {nc[1], nc[2], nc[3], (nc[4] or 1) * opacity} end
                        if off then dx, dy, s = dx + (off.x or 0), dy + (off.y or 0), s * (off.scale or 1) end
                    end
                end
            end
        end

        local spacing = isCJK(c) and self.config.letterSpacingCJK or self.config.letterSpacingLatin
        local w = self.resources.font:getWidth(c) * s
        
        if curX + w + spacing > startX + limit then
            curX = startX
            curY = curY + self.config.lineSpacing
        end

        love.graphics.setColor(unpack(ec))
        love.graphics.print(c, curX + dx, curY + dy, 0, s, s)
        curX = curX + w + spacing
    end
end

function LoveDialogue:advance()
    if self.state.status ~= "active" then
        if self.state.status == "fading_in" then
             self.state.status = "active"
             self.state.boxOpacity = 1
        end
        return
    end

    local line = self.state.lines[self.state.currentLineIndex]
    
    if self.state.choiceMode then
        local choice = self.state.activeChoices[self.state.selectedChoice]
        self:triggerPluginEvent("onChoiceSelected", self.state.selectedChoice, choice)
        
        if choice.target and self.state.scenes[choice.target] then
            self.state.currentLineIndex = self.state.scenes[choice.target]
        else
            self.state.currentLineIndex = self.state.currentLineIndex + 1
        end
        self:processCurrentLine()
        
    elseif self.state.displayedText ~= self.state.fullText then
        self.state.displayedText = self.state.fullText
        self:triggerPluginEvent("onTextSkipped")
    elseif line.isEnd then
        self:endDialogue()
    else
        self.state.currentLineIndex = self.state.currentLineIndex + 1
        self:processCurrentLine()
    end
end

function LoveDialogue:keypressed(key)
    if not self.state.isActive then return end
    
    for _, p in ipairs(self.plugins) do
        if p.handleKeyPress and p.handleKeyPress(self, self.config.pluginData[p.name], key) then return end
    end

    local c = self.config.controls
    local function is(k, list) for _, v in ipairs(list) do if v == k then return true end end return false end

    if is(key, c.toggleSpeed) then
        local keys = {"slow", "normal", "fast"}
        local n = (self.state.currentSpeedSetting == "slow" and 2) or (self.state.currentSpeedSetting == "normal" and 3) or 1
        self.state.currentSpeedSetting = keys[n]
        self.state.typingSpeed = self.config.speeds[self.state.currentSpeedSetting]
    elseif is(key, c.toggleAuto) then
        self.state.autoAdvance = not self.state.autoAdvance
        self:triggerPluginEvent("onAutoAdvanceToggled", self.state.autoAdvance)
    elseif key == self.config.skipKey then
        if self.state.displayedText ~= self.state.fullText and not self.state.choiceMode then
            self.state.displayedText = self.state.fullText
        end
    elseif self.state.choiceMode then
        if is(key, c.up) then
            self.state.selectedChoice = math.max(1, self.state.selectedChoice - 1)
        elseif is(key, c.down) then
            self.state.selectedChoice = math.min(#self.state.activeChoices, self.state.selectedChoice + 1)
        elseif is(key, c.next) then
            self:advance()
        end
    elseif is(key, c.next) then
        self:advance()
    end
end

function LoveDialogue:destroy()
    ResourceManager:releaseInstance(self.instanceId)
    for _, p in ipairs(self.plugins) do
        if p.cleanup then p.cleanup(self, self.config.pluginData[p.name]) end
    end
    self.plugins = {}
end

function LoveDialogue:endDialogue()
    self:triggerPluginEvent("onDialogueEnd")
    if self.config.enableFadeOut then
        self.state.status = "fading_out"
    else
        self.state.isActive = false
        self:destroy()
    end
end

function LoveDialogue:adjustLayout()
    local w, h = love.graphics.getDimensions()
    self.config.boxHeight = math.floor(h * 0.25)
    self.config.padding = math.floor(w * 0.02)
    -- Reload fonts with new sizes. Do NOT release the entire instance here!
    -- Fonts are cheap to load/unload, but releasing textures breaks Characters.
    local fontSize = math.floor(h * 0.025)
    self.resources.font = ResourceManager:getFont(self.instanceId, fontSize, nil, "main_font")
    self.resources.nameFont = ResourceManager:getFont(self.instanceId, math.floor(h * 0.03), nil, "name_font")
    
    -- Dynamically update line spacing to prevent overlap
    self.config.lineSpacing = math.floor(self.resources.font:getHeight() * 1.5)
    
    if self.config.useNinePatch then self:loadNinePatch() end
end

function LoveDialogue.play(file, conf)
    local d = LoveDialogue.new(conf)
    if conf and conf.theme then
        local t = ThemeParser.parseTheme(conf.theme)
        if t then ThemeParser.applyTheme(d, t) end
    end
    d:loadFromFile(file)
    d:start()
    return d
end

return LoveDialogue