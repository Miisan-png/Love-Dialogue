# LoveDialogue

LoveDialogue is a lightweight, flexible, and robust dialogue engine for the Love2D framework. It features a custom scripting language, rich text effects, character portrait management, logic/variable support, and a plugin system.

![License](https://img.shields.io/badge/license-MIT-blue.svg)

## Features

*   **Simple Scripting**: Write dialogue in an easy-to-read .ld format.
*   **Rich Text Effects**: Built-in support for wave, shake, color, bold, and nested effects.
*   **Logic System**: Variables (`$ gold = 10`) and Conditionals (`[if: gold > 5]`).
*   **Choice System**: Create branching narratives with infinite options and logic-gating.
*   **Signal System**: Trigger Lua callbacks from the script to control your game (e.g., `[signal: StartBattle]`).
*   **Portrait Management**: Support for simple images (`@portrait`) AND optimized spritesheets (`@sheet`/`@frame`).
*   **Resource Management**: Efficient reference-counting system for images and fonts to prevent memory leaks.
*   **Responsive Layout**: Auto-adjusts font sizes, text boxes, and line spacing when the window resizes.
*   **Plugin System**: Extend functionality with custom Lua plugins.

## Getting Started

### Installation

Copy the `LoveDialogue` folder into your project's directory.

### Basic Usage

1.  **Require the module**:
    ```lua
    local LoveDialogue = require("LoveDialogue")
    ```

2.  **Initialize and Play**:
    ```lua
    function love.load()
        local config = {
            boxHeight = 200,
            portraitEnabled = true,
            portraitSize = 150,
            initialVariables = { coins = 0 }
        }
        -- load and start playing a script
        dialogue = LoveDialogue.play("scripts/chapter1.ld", config)
        
        -- Listen for signals from the script
        dialogue.onSignal = function(name, args)
            if name == "GiveItem" then
                print("Giving item:", args)
            end
        end
    end
    ```

3.  **Update and Draw**:
    ```lua
    function love.update(dt)
        if dialogue then dialogue:update(dt) end
    end

    function love.draw()
        if dialogue then dialogue:draw() end
    end

    function love.keypressed(key)
        if dialogue then dialogue:keypressed(key) end
    end
    ```

## Script Syntax (.ld)

### 1. Variables & Logic
Initialize and update variables using `$`.
```ini
$ gold = 100
$ name = "Hero"
```

Use `[if]`, `[else]`, and `[endif]` for flow control.
```ini
[if: gold >= 50]
    Shopkeeper: You look rich!
[else]
    Shopkeeper: Get out of here, poor peasant!
[endif]
```

### 2. Portraits (Spritesheets)
Define a sheet once, then map frames to expressions.
```ini
@sheet Hero assets/hero_sheet.png 100 100
@frame Hero Default 1
@frame Hero Happy 2
@frame Hero Angry 5

Hero: (Happy) This is efficient!
```

### 3. Dialogue & Interpolation
Use `${var}` to insert variable values.
```ini
Hero: I have ${gold} gold pieces.
```

### 4. Signals (Events)
Trigger code in your main game loop.
```ini
[signal: PlaySound explosion.wav]
[signal: ChangeLevel forest]
```

### 5. Choices
Choices can have conditions attached.
```ini
-> Buy Potion (50g) [target:buy] [if: gold >= 50]
-> Leave [target:leave]
```

## License

This project is licensed under the MIT License.