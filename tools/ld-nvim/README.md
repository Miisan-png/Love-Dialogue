# LoveDialogue Neovim Plugin

Syntax highlighting and filetype support for LoveDialogue (.ld) files in Neovim.

## Features

- Syntax highlighting for all LoveDialogue constructs
- Automatic filetype detection for `.ld` files
- Comment support (`//`)
- Proper indentation (2 spaces)
- Code folding based on scene labels
- Auto-pairs support for brackets

## Installation

### Using vim-plug
```vim
Plug 'miisan/ld-nvim', {'for': 'ld'}
```

### Using packer.nvim
```lua
use {'miisan/ld-nvim', ft = 'ld'}
```

### Manual Installation
Copy the plugin files to your Neovim configuration:
```bash
cp -r ld-nvim/* ~/.config/nvim/
```

## Usage

The plugin automatically activates when you open `.ld` files. All LoveDialogue syntax will be properly highlighted including:

- Comments (`//`)
- Variables (`$ name = value`)
- Character dialogue (`Name: Text`)
- Commands (`[signal: event]`)
- Text effects (`{wave:1}text{/wave}`)
- Choices (`-> Option [target:label]`)
- And more!

## License

MIT License
