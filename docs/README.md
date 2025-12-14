# LoveDialogue Documentation

Welcome to the documentation for **LoveDialogue**. This guide will help you integrate and master the dialogue engine for your Love2D games.

## Table of Contents

1.  [Configuration](#configuration)
2.  [Scripting Reference](#scripting-reference)
3.  [Text Effects](#text-effects)
4.  [Logic & Signals](#logic--signals)
5.  [Plugin System](#plugin-system)

---

## Configuration

When calling `LoveDialogue.play(file, config)`, you can pass a table with the following options:

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `boxHeight` | number | `150` | Height of the dialogue box in pixels. |
| `padding` | number | `20` | Padding inside the box. |
| `boxColor` | table | `{0.1, 0.1, 0.1, 0.9}` | Background color `{r, g, b, a}`. |
| `textColor` | table | `{1, 1, 1, 1}` | Default text color. |
| `nameColor` | table | `{1, 0.8, 0.2, 1}` | Default character name color. |
| `typingSpeed` | number | `0.05` | Seconds per character (lower is faster). |
| `portraitEnabled` | boolean | `true` | Whether to show portraits. |
| `character_type` | number | `0` | `0` = Horizontal (VN style), `1` = Vertical (Standing art). |
| `autoLayoutEnabled` | boolean | `true` | Auto-resize fonts/box on window resize. |
| `skipKey` | string | `"f"` | Key to skip current typing animation. |
| `initialVariables`| table  | `{}` | Starting values for script variables. |

---

## Scripting Reference

Scripts are plain text files. Lines starting with `//` are comments.

### 1. Defining Portraits
At the very top of your file:
```ini
@portrait CharacterName path/to/image.png
```

### 2. Labels (Scenes)
Labels mark the start of a section. You can jump to them using choices.
```ini
[my_scene_name]
```

### 3. Dialogue
Format: `Name: Text`
```ini
Alice: Hi there!
Bob: (Happy) Hello Alice!
```

### 4. Logic & Variables
Set variables with `$`:
```ini
$ coins = 100
$ met_boss = true
```

Branch flow with `[if]`:
```ini
[if: coins > 50]
    Merchant: Please, come in!
[else]
    Merchant: Shoo!
[endif]
```

### 5. Signals
Trigger external game events (handled via `dialogue.onSignal` in Lua).
```ini
[signal: CameraShake 5]
```

### 6. Choices
Choices appear at the end of a dialogue block.
```ini
-> Option Text [target:label_name] [if: condition]
```

---

## Text Effects

Wrap text in tags to apply effects. Tags can be nested.

| Tag | Usage | Description |
| :--- | :--- | :--- |
| **Color** | `{color:RRGGBB}Text{/color}` | Changes text color (Hex). |
| **Wave** | `{wave:intensity}Text{/wave}` | Text moves in a sine wave. |
| **Shake** | `{shake:intensity}Text{/shake}` | Text jitters randomly. |

**Example:**
```ini
Wizard: {wave:1}The magic is unstable!{/wave} {shake:2}Run!{/shake}
```

---

## Plugin System

You can extend functionality by registering plugins. A plugin is a Lua table with event hooks.

### Creating a Plugin

```lua
local MyPlugin = {
    name = "MyPlugin",
    init = function(dialogue, data)
        print("Plugin initialized")
    end,
    onCharacterTyped = function(dialogue, data, char)
        -- Play sound per char?
    end
}
return MyPlugin
```

### Registering
```lua
local PluginManager = require("LoveDialogue.PluginManager")
PluginManager:register(MyPlugin)
```