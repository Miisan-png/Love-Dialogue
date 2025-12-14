// Story Demo
[load_theme: demo/theme.ld]

// Define Sprite Atlases
@atlas Miisan demo/assets/character_portraits/girl1_atlas.png
@rect Miisan Happy 0 0 100 108
@rect Miisan Sad 100 0 100 108
@rect Miisan Angry 202 0 100 108
@voice Miisan demo/assets/sfx/blip.wav

@atlas Eiisan demo/assets/character_portraits/girl2_atlas.png
@rect Eiisan Happy 0 0 100 108
@voice Eiisan demo/assets/sfx/low.wav

@atlas Wiisan demo/assets/character_portraits/girl3_atlas.png
@rect Wiisan Happy 0 0 100 108
@voice Wiisan demo/assets/sfx/high.wav

// Initialize logic
$ coins = 0
$ name = "Traveller"

[start]
Miisan: (Happy) Hello ${name}! This is the Logic & Story Demo.
Miisan: (Happy) I check variables. You have ${coins} coins.

[if: coins == 0]
    Eiisan: (Happy) You are broke! Here, take 100 coins.
    $ coins = 100
    [signal: PlaySound demo/assets/sfx/high.wav]
[else]
    Eiisan: (Happy) You kept your coins from last time!
[endif]

Miisan: (Happy) Now you have ${coins} coins.
Wiisan: (Happy) Do you want to buy the secret item (50g)?

-> Yes [target:buy] [if: coins >= 50]
-> No [target:skip]
-> Return to Menu [target:menu]

[buy]
$ coins = coins - 50
Miisan: (Happy) Sold! You have ${coins} left.
-> Back to loop [target:start]

[skip]
Miisan: (Sad) Boring...
-> Back to loop [target:start]

[menu]
[signal: LoadScript demo/launcher.ld]
(end)