local PluginManager = {}
PluginManager.plugins = {}
-- Register a plugin
-- @param plugin table: The plugin implementation
-- @return boolean: Success or failure
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

-- Unregister a plugin by name
-- @param name string: The plugin name
-- @return boolean: Success or failure
function PluginManager:unregister(name)
    if not self.plugins[name] then
        print("Warning: Plugin '" .. name .. "' is not registered")
        return false
    end
    
    self.plugins[name] = nil
    return true
end

-- Get a plugin by name
-- @param name string: The plugin name
-- @return table: The plugin implementation or nil if not found
function PluginManager:getPlugin(name)
    return self.plugins[name]
end

-- Get all registered plugins
-- @return table: A list of all registered plugins
function PluginManager:getAllPlugins()
    local result = {}
    for _, plugin in pairs(self.plugins) do
        table.insert(result, plugin)
    end
    return result
end

-- Load plugins from a directory
-- @param directory string: The directory path
-- @return number: Number of plugins loaded
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
                if self:register(plugin) then
                    count = count + 1
                end
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
        
        init = function(dialogue, pluginData)
            print(name .. " initialized")
        end,
        
        cleanup = function(dialogue, pluginData)
            print(name .. " cleaned up")
        end,
        
        -- Dialogue event hooks
        onDialogueCreated = function(dialogue, pluginData)
            -- Called when a dialogue instance is created
        end,
        
        onFileLoaded = function(dialogue, pluginData, filePath, lines, characters, scenes)
            -- Called when a dialogue file is loaded
        end,
        
        onDialogueStart = function(dialogue, pluginData)
            -- Called when dialogue starts
        end,
        
        onDialogueEnd = function(dialogue, pluginData)
            -- Called when dialogue ends
        end,
        
        onBeforeUpdate = function(dialogue, pluginData, dt)
            -- Called before dialogue update
        end,
        
        onAfterUpdate = function(dialogue, pluginData, dt)
            -- Called after dialogue update
        end,
        
        onBeforeDraw = function(dialogue, pluginData)
            -- Called before dialogue draw
        end,
        
        onAfterDraw = function(dialogue, pluginData)
            -- Called after dialogue draw
        end,
        
        onCharacterTyped = function(dialogue, pluginData, char, fullText)
            -- Called when a character is typed in the typewriter effect
        end,
        
        onTextSkipped = function(dialogue, pluginData)
            -- Called when text is skipped
        end,
        
        onBeforeAdvance = function(dialogue, pluginData)
            -- Called before advancing to next dialogue line
        end,
        
        onAfterAdvance = function(dialogue, pluginData)
            -- Called after advancing to next dialogue line
        end,
        
        onBeforeDialogueSet = function(dialogue, pluginData, dialogueLine)
            -- Called before setting current dialogue line
        end,
        
        onAfterDialogueSet = function(dialogue, pluginData, dialogueLine)
            -- Called after setting current dialogue line
        end,
        
        onChoiceNavigation = function(dialogue, pluginData, direction, newIndex)
            -- Called when navigating choices
        end,
        
        onChoiceSelected = function(dialogue, pluginData, choiceIndex, choice)
            -- Called when a choice is selected
        end,
        
        onSpeedChanged = function(dialogue, pluginData, speedSetting, typingSpeed)
            -- Called when text speed is changed
        end,
        
        onAutoAdvanceToggled = function(dialogue, pluginData, enabled)
            -- Called when auto-advance is toggled
        end,
        
        onFadeInComplete = function(dialogue, pluginData)
            -- Called when fade-in animation completes
        end,
        
        onFadeOutComplete = function(dialogue, pluginData)
            -- Called when fade-out animation completes
        end,
        
        onLayoutAdjusted = function(dialogue, pluginData, windowWidth, windowHeight)
            -- Called when layout is adjusted
        end,
        
        onThemeLoaded = function(dialogue, pluginData, theme)
            -- Called when a theme is loaded
        end,
        
        onBeforeDestroy = function(dialogue, pluginData)
            -- Called before dialogue is destroyed
        end,
        
        -- Optional hooks for modifying behavior
        modifyDeltaTime = function(dialogue, pluginData, dt)
            -- Can be used to modify the delta time for animations
            return dt
        end,
        
        handleKeyPress = function(dialogue, pluginData, key)
            -- Return true if the key press was handled by this plgin
            return false
        end
    }
end

return PluginManager