// Load custom theme
[load_theme: demo/theme.ld]

// Define Sprite Atlases
@atlas Miisan demo/assets/character_portraits/girl1_atlas.png
@rect Miisan Happy 0 0 100 108
@rect Miisan Sad 100 0 100 108
@rect Miisan Angry 202 0 100 108
@voice Miisan demo/assets/sfx/blip.wav

@atlas Eiisan demo/assets/character_portraits/girl2_atlas.png
@rect Eiisan Happy 0 0 100 108
@rect Eiisan Sad 100 0 100 108
@rect Eiisan Neutral 202 0 100 108

@atlas Wiisan demo/assets/character_portraits/girl3_atlas.png
@rect Wiisan Happy 0 0 100 108
@rect Wiisan Sad 100 0 100 108
@rect Wiisan Mad 202 0 100 108

// Initialize logic
$ coins = 0
$ name = "Traveller"

[start]
Miisan: (Happy) Hello ${name}! I can talk now! Do you hear the blip?
// Move Miisan 20px right
[move: Miisan 20 0 0.5]
Miisan: (Sad) I moved 20 pixels to the right!
// Move back
[move: Miisan 0 0 0.5]
Miisan: (Happy) Back to normal.

Eiisan: (Happy) I can do that too!
// Move Eiisan Up
[move: Eiisan 0 -30 0.3]
Eiisan: (Happy) I jumped!
[move: Eiisan 0 0 0.3]

Wiisan: (Happy) Save and Load test!
Miisan: Press 'S' to save, then restart the game and press 'L'.
Miisan: Or just choose options and check variables.

-> Gain 50 Gold [target:gain]
-> Spend 50 Gold [target:spend] [if: coins >= 50]
-> End [target:end]

[gain]
$ coins = coins + 50
Miisan: You have ${coins} coins.
-> Back to start [target:start]

[spend]
$ coins = coins - 50
Miisan: You spent it! ${coins} left.
-> Back to start [target:start]

[end]
Miisan: (Happy) Thanks for playing! (end)