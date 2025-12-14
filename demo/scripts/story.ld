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
Miisan: (Happy) Hello ${name}! This is the {color:FFD700}Logic & Effects{/color} Demo.
Miisan: (Happy) I can do {wave:1}wavy text{/wave}, {shake:1}shaky text{/shake}, and {jiggle:1}jiggly text{/jiggle}!

[if: coins == 0]
    Eiisan: (Sad) You are {color:FF0000}{shake:1}BROKE!{/shake}{/color}
    Eiisan: (Neutral) Here, take 100 coins.
    $ coins = 100
    [signal: PlaySound demo/assets/sfx/high.wav]
[else]
    Eiisan: (Happy) You are {color:00FF00}{wave:1}RICH!{/wave}{/color}
[endif]

Miisan: (Happy) Now you have ${coins} coins.
Wiisan: (Happy) Do you want to buy the {bold:2}Secret Item{/bold} (50g)?

-> Buy {color:FFFF00}Secret Item{/color} [target:buy] [if: coins >= 50]
-> No thanks [target:skip]
-> {italic:right}Return to Menu{/italic} [target:menu]

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