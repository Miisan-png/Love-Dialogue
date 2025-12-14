// Load custom theme
[load_theme: demo/theme.ld]

// Define Character Sheets
// Name, Path, FrameWidth, FrameHeight
@sheet Miisan demo/assets/characters/girl1/sheet.png 100 100
@frame Miisan Default 1
@frame Miisan Happy 2

@sheet Eiisan demo/assets/characters/girl2/sheet.png 100 100
@frame Eiisan Default 1
@frame Eiisan Happy 2

@sheet Wiisan demo/assets/characters/girl3/sheet.png 100 100
@frame Wiisan Default 1
@frame Wiisan Happy 2

// Initialize logic
$ coins = 0
$ has_met_secret = false
$ name = "Traveller"

[start]
Miisan: (Happy) Hello ${name}! Look, I am using a spritesheet now!
Eiisan: (Default) Me too. We can switch expressions easily.
Wiisan: (Happy) Yay! Less memory usage!

Miisan: (Default) Let's test the signal again.
[signal: ChangeBG 0.5 0 0]
Eiisan: (Happy) Red background!
[signal: ChangeBG 0.1 0.1 0.2]
Wiisan: (Default) Back to normal.

Miisan: Do you want some coins?
-> Yes please! [target:get_coins]
-> No thanks. [target:end]

[get_coins]
$ coins = coins + 50
Miisan: (Happy) Here is 50 coins. You have ${coins} now.
-> End Demo [target:end]

[end]
Miisan: (Happy) Thanks for checking out LoveDialogue v1.0!
Eiisan: (Happy) Check the code to see how easy spritesheets are.
Wiisan: (Happy) Bye bye! (end)