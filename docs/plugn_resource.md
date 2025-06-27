# LoveDialogue - Resource Management and Plugin System Guide

This guide explains how to use the enhanced resource management system and plugin architecture in LoveDialogue.

## Resource Management

The new resource management system ensures that all Love2D resources (images, fonts, quads, etc.) are properly tracked and released when no longer needed, preventing memory leaks in long-running games.

### Using ResourceManager

The `ResourceManager` module handles tracking and releasing resources:

```lua
local ResourceManager = require("LoveDialogue.ResourceManager")

-- Create a tracked image
local image = ResourceManager:newImage(instanceId, "path/to/image.png", "my_image")

-- Create a tracked font
local font = ResourceManager:newFont(instanceId, 16, nil, "my_font")

-- Track an existing resource
local quad = love.graphics.newQuad(0, 0, 32, 32, 64, 64)
ResourceManager:track(instanceId, "quads", quad, "my_quad")

-- When done, release all resources for an instance
ResourceManager:releaseInstance(instanceId)

-- At the end of your game, release everything
ResourceManager:releaseAll()
```

### Key Benefits

1. **Automatic Cleanup**: Resources are automatically released when a dialogue ends
2. **Organized Tracking**: Resources are categorized by type and instance
3. **Error Handling**: Graceful handling of resource loading failures
4. **Debug Support**: Resource names make it easier to debug issues

## Plugin System

The plugin system allows you to extend LoveDialogue with new features without modifying the core code.

### Creating a Plugin

A plugin is a Lua table with a set of callbacks that hook into LoveDialogue's lifecycle:

```lua
local MyPlugin = {
    name = "MyPluginName",         -- Required: unique name
    description = "Description",   -- Optional: description
    version = "1.0.0",             -- Optional: version
    author = "Your Name"           -- Optional: author
}

-- Initialization function
function MyPlugin.init(dialogue, pluginData)
    -- This is called when the plugin is first registered with a dialogue instance
    -- pluginData is a table where you can store plugin-specific data
    pluginData.myCounter = 0
end

-- Event hook example
function MyPlugin.onBeforeUpdate(dialogue, pluginData, dt)
    -- Called before each update
    pluginData.myCounter = pluginData.myCounter + 1
end

-- Cleanup function
function MyPlugin.cleanup(dialogue, pluginData)
    -- Called when dialogue is destroyed
    -- Clean up any resources your plugin created
end

return MyPlugin
```

### Available Plugin Hooks

Plugins can implement any of these hooks to extend functionality:

#### Lifecycle Hooks
- `init(dialogue, pluginData)` - Plugin initialization
- `cleanup(dialogue, pluginData)` - Plugin cleanup
- `onDialogueCreated(dialogue, pluginData)` - When dialogue instance is created
- `onDialogueStart(dialogue, pluginData)` - When dialogue starts
- `onDialogueEnd(dialogue, pluginData)` - When dialogue ends
- `onBeforeDestroy(dialogue, pluginData)` - Before dialogue is destroyed

#### Update and Draw Hooks
- `onBeforeUpdate(dialogue, pluginData, dt)` - Before update
- `onAfterUpdate(dialogue, pluginData, dt)` - After update
- `onBeforeDraw(dialogue, pluginData)` - Before draw
- `onAfterDraw(dialogue, pluginData)` - After draw
- `modifyDeltaTime(dialogue, pluginData, dt)` - Modify delta time (return new dt)

#### Text and Dialogue Hooks
- `onCharacterTyped(dialogue, pluginData, char, fullText)` - When a character is typed
- `onTextSkipped(dialogue, pluginData)` - When text is skipped
- `onBeforeAdvance(dialogue, pluginData)` - Before advancing to next line
- `onAfterAdvance(dialogue, pluginData)` - After advancing to next line
- `onBeforeDialogueSet(dialogue, pluginData, dialogueLine)` - Before setting current line
- `onAfterDialogueSet(dialogue, pluginData, dialogueLine)` - After setting current line

#### Choice Hooks
- `onChoiceNavigation(dialogue, pluginData, direction, newIndex)` - When navigating choices
- `onChoiceSelected(dialogue, pluginData, choiceIndex, choice)` - When selecting a choice

#### Other Hooks
- `onSpeedChanged(dialogue, pluginData, speedSetting, typingSpeed)` - When text speed changes
- `onAutoAdvanceToggled(dialogue, pluginData, enabled)` - When auto-advance is toggled
- `onFadeInComplete(dialogue, pluginData)` - When fade-in completes
- `onFadeOutComplete(dialogue, pluginData)` - When fade-out completes
- `onLayoutAdjusted(dialogue, pluginData, windowWidth, windowHeight)` - When layout adjusts
- `onThemeLoaded(dialogue, pluginData, theme)` - When theme is loaded
- `handleKeyPress(dialogue, pluginData, key)` - Handle key press (return true if handled)

### Registering a Plugin

#### Automatic Loading

You can put plugins in a `plugins` directory and use:

```lua
-- In your game initialization
local PluginManager = require("LoveDialogue.PluginManager")
PluginManager:loadPluginsFromDirectory("LoveDialogue/plugins")
```

#### Manual Registration

```lua
local PluginManager = require("LoveDialogue.PluginManager")
local MyPlugin = require("path.to.MyPlugin")

PluginManager:register(MyPlugin)
```

### Using Plugins with Dialogue

```lua
local LoveDialogue = require("LoveDialogue")

local config = {
    -- Basic config options
    boxHeight = 150,
    typingSpeed = 0.05,
    
    -- Register plugins to use
    plugins = {"SoundEffects", "Animations", "MyPlugin"},
    
    -- Configure plugins
    pluginData = {
        SoundEffects = {
            typingSound = "sounds/typing.wav",
            advanceSound = "sounds/advance.wav"
        },
        MyPlugin = {
            -- Custom configuration for your plugin
            customOption = true
        }
    }
}

local dialogue = LoveDialogue.play("dialogue.ld", config)
```

## Example: Sound Effects Plugin

The included `SoundEffectsPlugin` adds audio support to LoveDialogue:

```lua
-- In your game setup
local PluginManager = require("LoveDialogue.PluginManager")
local SoundEffectsPlugin = require("LoveDialogue.plugins.SoundEffectsPlugin")
PluginManager:register(SoundEffectsPlugin)

-- When creating dialogue
local config = {
    plugins = {"SoundEffects"},
    pluginData = {
        SoundEffects = {
            typingSound = "sounds/typing.wav",
            typingSoundVolume = 0.5,
            advanceSound = "sounds/advance.wav",
            choiceSound = "sounds/select.wav",
            choiceNavSound = "sounds/navigate.wav",
            characterSounds = {
                -- Character-specific sounds
                Miisan = "sounds/miisan_voice.wav",
                Eiisan = "sounds/eiisan_voice.wav"
            },
            taggedSounds = {
                -- Play sounds when text effects are used
                shake = "sounds/shake.wav",
                wave = "sounds/wave.wav"
            }
        }
    }
}

local dialogue = LoveDialogue.play("dialogue.ld", config)
```

## Creating Your Own Plugins

1. Create a new Lua file in the `plugins` directory
2. Use `PluginManager:createPluginTemplate()` as a starting point
3. Implement the hooks you need
4. Register the plugin with `PluginManager:register()`

## Best Practices

1. **Resource Management**:
   - Always use ResourceManager to create and track Love2D resources
   - Use the instanceId provided to your plugin for resource tracking
   - Clean up any non-Love2D resources in your plugin's cleanup function

2. **Plugin Development**:
   - Give your plugin a unique, descriptive name
   - Store plugin-specific data in the pluginData table
   - Document your plugin's configuration options
   - Avoid modifying dialogue state directly unless necessary
   - Use the appropriate hooks for your functionality

3. **Performance**:
   - Be mindful of performance in frequently called hooks (update, draw)
   - Consider using the modifyDeltaTime hook for time-based effects
   - Cache computed values rather than recalculating them each frame

---

With this system, you can easily extend LoveDialogue with new features like:
- Sound effects and voice acting
- Advanced animations and transitions
- Custom UI elements and themes
- Input methods (gamepad, touch, etc.)
- Analytics and debugging tools
- Integration with other systems