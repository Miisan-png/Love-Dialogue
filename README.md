# LoveDialogue

![LoveDialogue Logo](repo/Logo.svg)

LoveDialogue is a powerful and flexible dialogue game engine for LÖVE (Love2D) games, featuring rich text effects, branching dialogues, character portraits, and extensive customization options.

## Features

- **Easy-to-use dialogue system** with rich text formatting
- **Advanced text effects**:
  - Color formatting with hex codes
  - Wave animation with configurable intensity
  - Jiggle and shake effects for emphasis
  - Bold text with configurable intensity
  - Italic text with direction control
- **Comprehensive character system**:
  - Character portraits with expression support
  - Both standalone portraits and sprite sheet support
  - Custom character colors and name colors
- **Flexible UI options**:
  - Classic solid color dialogue boxes
  - 9-patch dialogue boxes with custom graphics
  - Vertical character portrait mode
- **Dialogue flow control**:
  - Branching dialogue with choices
  - Scene labels for better organization
  - Different text display speeds
  - Auto-advance functionality
- **Theming and customization**:
  - Complete theme support via theme files
  - Custom fonts and font sizes
  - Adjustable box dimensions and padding
- **Multilingual support**:
  - Latin and CJK (Chinese, Japanese, Korean) text handling
  - Configurable character spacing for different languages
- **Responsive design**:
  - Auto-layout capabilities for different screen sizes
  - Adjustable fade animations
  - Configurable typewriter effect

## Showcase
![LoveDialogue Showcase](repo/Showcase.png)
![LoveDialogue Showcase 2](repo/Showcase_2.png)

## Installation

1. Copy the `LoveDialogue` folder into your LÖVE project directory
2. Require the module in your `main.lua`:

```lua
local LoveDialogue = require "LoveDialogue"
```

## Basic Usage

```lua
local LoveDialogue = require "LoveDialogue"

local myDialogue

function love.load()
    myDialogue = LoveDialogue.play("dialogue.ld")
end

function love.update(dt)
    if myDialogue then
        myDialogue:update(dt)
    end
end

function love.draw()
    if myDialogue then
        myDialogue:draw()
    end
end

function love.keypressed(key)
    if myDialogue then
        myDialogue:keypressed(key)
    end
end
```

## Dialogue File (.ld) Syntax

### Basic Dialogue
```
Character: This is a basic dialogue line.
AnotherCharacter: This will show after the first line.
```

### Text Effects
```
Character: This text will {wave:1}wave{/wave} and {color:FF0000}be red{/color}.
Character: This text will {jiggle:2}jiggle{/jiggle} and {shake:1}shake{/shake}.
Character: You can also make text {bold:2}bold{/bold} or {italic:left}italic{/italic}.
```

### Character Portraits
```
@portrait Character assets/portraits/character.png
Character: This line will show with the character's portrait!
Character(Happy): This uses the "Happy" expression.
```

### Scenes and Branching
```
[start]
Character: Make a choice:
-> Go to scene A [target:sceneA]
-> Go to scene B [target:sceneB]

[sceneA]
Character: You chose scene A!

[sceneB]
Character: You chose scene B!
```

### Ending Dialogue
```
Character: This is the end of our conversation. (end)
```

## Configuration Options

You can customize the dialogue system by passing a config table:

```lua
local config = {
    -- Appearance
    fontSize = 16,                    -- Base font size
    nameFontSize = 18,                -- Character name font size
    boxColor = {0.1, 0.1, 0.1, 0.9},  -- Dialog box background color
    textColor = {1, 1, 1, 1},         -- Text color
    nameColor = {1, 0.8, 0.2, 1},     -- Character name color
    padding = 20,                     -- Box padding
    boxHeight = 150,                  -- Dialog box height
    
    -- Text spacing
    letterSpacingLatin = 4,           -- Spacing between Latin characters
    letterSpacingCJK = 10,            -- Spacing between CJK characters
    lineSpacing = 16,                 -- Spacing between lines
    
    -- 9-patch support
    useNinePatch = true,              -- Enable 9-patch dialogue boxes
    ninePatchPath = "path/to/9patch.png", -- Path to 9-patch image
    edgeWidth = 10,                   -- 9-patch edge width
    edgeHeight = 10,                  -- 9-patch edge height
    
    -- Animation
    typingSpeed = 0.05,               -- Text typing speed
    fadeInDuration = 0.5,             -- Fade in animation duration
    fadeOutDuration = 0.5,            -- Fade out animation duration
    enableFadeIn = true,              -- Enable fade in animation
    enableFadeOut = true,             -- Enable fade out animation
    
    -- Portrait settings
    portraitSize = 100,               -- Size of character portraits
    portraitEnabled = true,           -- Enable/disable portraits
    character_type = false,           -- false=normal, true=vertical portrait
    
    -- Text control
    skipKey = "f",                    -- Key to skip current text
    textSpeeds = {                    -- Different text speed presets
        slow = 0.08,
        normal = 0.05,
        fast = 0.02
    },
    initialSpeedSetting = "normal",   -- Initial text speed
    
    -- Auto-advance
    autoAdvance = false,              -- Enable auto advancing
    autoAdvanceDelay = 3.0,           -- Delay before auto-advancing
    
    -- Layout
    autoLayoutEnabled = true         -- Enable responsive layout
}

myDialogue = LoveDialogue.play("dialogue.ld", config)
```

## Theming Support

Create a theme file or include it directly in your dialogue file:

```
[theme]
box_color: 26, 26, 26, 230
text_color: 255, 255, 255, 255
name_color: 255, 204, 51, 255
font_size: 16
name_font_size: 18
box_height: 150
padding: 20
typing_speed: 0.05
fade_in: 0.5
fade_out: 0.5
```

Apply the theme:

```lua
myDialogue = LoveDialogue.play("dialogue.ld", {
    theme = "theme.txt"
})
```

## Character System

Characters can have multiple expressions that can be switched during dialogue:

```lua
-- Character with default expression
myDialogue.characters["Character"] = LD_Character.new("Character")

-- Adding expressions
local expression = {
    quad = love.graphics.newQuad(0, 0, 100, 100, 100, 100),
    texture = love.graphics.newImage("character.png")
}
myDialogue.characters["Character"]:addExpression("Happy", expression)
```

## User Controls

Default controls:
- `SPACE` or `ENTER`: Advance dialogue or select choice
- `UP` and `DOWN` arrows: Navigate choices
- `F`: Skip current text (configurable)
- `T`: Cycle through text speeds
- `A`: Toggle auto-advance mode

## 9-Patch Support

LoveDialogue supports 9-patch images for dialogue boxes:

```lua
myDialogue = LoveDialogue.play("dialogue.ld", {
    useNinePatch = true,
    ninePatchPath = "path/to/9patch.png",
    edgeWidth = 10,
    edgeHeight = 10
})
```

## VS Code Extension

For syntax highlighting and better editing experience, use the "Love2D Dialog (.ld) Language Support" extension for Visual Studio Code.

[Download the extension here](https://marketplace.visualstudio.com/items?itemName=miisan-mi.ld-language-support)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.