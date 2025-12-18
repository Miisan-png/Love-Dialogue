# LoveDialogue Language Support

Syntax highlighting, snippets, and language support for LoveDialogue (.ld) files in Visual Studio Code.

## Features

- **Syntax Highlighting** - Full support for all LoveDialogue constructs
- **Code Snippets** - Quick insertion of common patterns
- **Auto-completion** - Bracket matching and auto-closing
- **Comment Support** - Line comments with `//`

## Supported Syntax

- Variables: `$ name = value`
- Character dialogue: `Name: Hello world!`
- Expressions: `Name: (Happy) I'm excited!`
- Commands: `[signal: event]`, `[bgm: music.wav]`
- Logic: `[if: condition]`, `[else]`, `[endif]`
- Choices: `-> Option [target:label] [if: condition]`
- Text effects: `{wave:1}text{/wave}`, `{color:FF0000}red{/color}`
- Portraits: `@atlas Name image.png`, `@voice Name sound.wav`

## Quick Start

1. Create a new file with `.ld` extension
2. Start typing - syntax highlighting activates automatically
3. Use snippets: type `scene`, `if`, `choice`, etc. and press Tab

## Snippets

- `scene` - Create dialogue scene
- `@atlas` - Define character atlas
- `@voice` - Add character voice
- `if` - Conditional block
- `choice` - Add choice option
- `signal` - Trigger game event
- `wave` - Wave text effect

## About LoveDialogue

LoveDialogue is a lightweight dialogue engine for Love2D games featuring rich text effects, character portraits, logic systems, and more.

## License

MIT License
