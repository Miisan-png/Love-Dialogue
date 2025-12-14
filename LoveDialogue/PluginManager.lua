local PluginManager = {}
PluginManager.plugins = {}

function PluginManager:register(plugin)
    if not plugin or type(plugin) ~= "table" then
        print("Error: Invalid plugin (must be a table)")
        return false
    end
    if not plugin.name then
        print("Error: Plugin must have a name")
        return false
    end
    if self.plugins[plugin.name] then
        print("Warning: Plugin '" .. plugin.name .. "' is already registered and will be overwritten")
    end
    self.plugins[plugin.name] = plugin
    print("Plugin '" .. plugin.name .. "' registered successfully")
    return true
end

function PluginManager:unregister(name)
    if not self.plugins[name] then
        print("Warning: Plugin '" .. name .. "' is not registered")
        return false
    end
    self.plugins[name] = nil
    return true
end

function PluginManager:getPlugin(name)
    return self.plugins[name]
end

function PluginManager:getAllPlugins()
    local result = {}
    for _, plugin in pairs(self.plugins) do table.insert(result, plugin) end
    return result
end

function PluginManager:loadPluginsFromDirectory(directory)
    if not love.filesystem.getInfo(directory) then
        print("Warning: Plugin directory '" .. directory .. "' does not exist")
        return 0
    end
    
    local files = love.filesystem.getDirectoryItems(directory)
    local count = 0
    
    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            local pluginPath = directory .. "/" .. file
            local success, plugin = pcall(require, pluginPath:gsub(".lua$", ""):gsub("/", "."))
            if success and type(plugin) == "table" and plugin.name then
                if self:register(plugin) then count = count + 1 end
            else
                print("Warning: Failed to load plugin from '" .. pluginPath .. "'")
            end
        end
    end
    return count
end

function PluginManager:createPluginTemplate(name, description)
    return {
        name = name or "Unnamed Plugin",
        description = description or "No description provided",
        version = "1.0.0",
        author = "Unknown",
        init = function(dialogue, pluginData) end,
        cleanup = function(dialogue, pluginData) end,
        onDialogueCreated = function(dialogue, pluginData) end,
        onFileLoaded = function(dialogue, pluginData, filePath, lines, characters, scenes) end,
        onDialogueStart = function(dialogue, pluginData) end,
        onDialogueEnd = function(dialogue, pluginData) end,
        onBeforeUpdate = function(dialogue, pluginData, dt) end,
        onAfterUpdate = function(dialogue, pluginData, dt) end,
        onBeforeDraw = function(dialogue, pluginData) end,
        onAfterDraw = function(dialogue, pluginData) end,
        onCharacterTyped = function(dialogue, pluginData, char, fullText) end,
        onTextSkipped = function(dialogue, pluginData) end,
        onBeforeAdvance = function(dialogue, pluginData) end,
        onAfterAdvance = function(dialogue, pluginData) end,
        onBeforeDialogueSet = function(dialogue, pluginData, dialogueLine) end,
        onAfterDialogueSet = function(dialogue, pluginData, dialogueLine) end,
        onChoiceNavigation = function(dialogue, pluginData, direction, newIndex) end,
        onChoiceSelected = function(dialogue, pluginData, choiceIndex, choice) end,
        onSpeedChanged = function(dialogue, pluginData, speedSetting, typingSpeed) end,
        onAutoAdvanceToggled = function(dialogue, pluginData, enabled) end,
        onFadeInComplete = function(dialogue, pluginData) end,
        onFadeOutComplete = function(dialogue, pluginData) end,
        onLayoutAdjusted = function(dialogue, pluginData, windowWidth, windowHeight) end,
        onThemeLoaded = function(dialogue, pluginData, theme) end,
        onBeforeDestroy = function(dialogue, pluginData) end,
        onUtteranceEnd = function(dialogue, pluginData) end,
        modifyDeltaTime = function(dialogue, pluginData, dt) return dt end,
        handleKeyPress = function(dialogue, pluginData, key) return false end
    }
end

return PluginManager