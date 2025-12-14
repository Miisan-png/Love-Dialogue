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
@voice Eiisan demo/assets/sfx/low.wav

@atlas Wiisan demo/assets/character_portraits/girl3_atlas.png
@rect Wiisan Happy 0 0 100 108
@rect Wiisan Sad 100 0 100 108
@rect Wiisan Mad 202 0 100 108
@voice Wiisan demo/assets/sfx/high.wav

// Initialize logic
$ coins = 0
$ name = "Traveller"

[start]
Miisan: (Happy) Hello ${name}! I sound like a normal anime girl.
Eiisan: (Happy) And I sound like a cool skeleton guy.
Wiisan: (Happy) I sound squeaky like a small animal!

Miisan: (Happy) See? We all have unique voices now.
[move: Miisan 20 0 0.5]
Miisan: (Sad) And I can still move around.
[move: Miisan 0 0 0.5]

Eiisan: (Happy) I love my low-pitched voice.
Wiisan: (Happy) Mine is definitely the cutest!

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