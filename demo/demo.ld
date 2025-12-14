// Load custom theme
[load_theme: demo/theme.ld]

// Define Sprite Atlases with Exact Coordinates
// x, y, width, height

// Girl 1
@atlas Miisan demo/assets/character_portraits/girl1_atlas.png
@rect Miisan Happy 0 0 100 108
@rect Miisan Sad 100 0 100 108
@rect Miisan Angry 202 0 100 108

// Girl 2
@atlas Eiisan demo/assets/character_portraits/girl2_atlas.png
@rect Eiisan Happy 0 0 100 108
@rect Eiisan Sad 100 0 100 108
@rect Eiisan Neutral 202 0 100 108

// Girl 3
@atlas Wiisan demo/assets/character_portraits/girl3_atlas.png
@rect Wiisan Happy 0 0 100 108
@rect Wiisan Sad 100 0 100 108
@rect Wiisan Mad 202 0 100 108

// Initialize logic
$ coins = 0
$ name = "Traveller"

[start]
Miisan: (Happy) Hello ${name}! Notice the fancy dialogue box?
Eiisan: (Happy) It's using a 9-patch image from the assets folder.
Wiisan: (Happy) It stretches perfectly to fit the window!

Miisan: (Sad) But I lost my coins...
$ coins = 10
Eiisan: (Happy) Don't worry, I found 10 coins!
Miisan: (Happy) Yay!

Miisan: (Happy) Let's test the signal again.
[signal: ChangeBG 0.5 0 0]
Eiisan: (Sad) Red!
[signal: ChangeBG 0.1 0.1 0.2]
Wiisan: (Happy) Blue.

Miisan: (Happy) Do you want to buy the secret?
-> Yes please! [target:buy_secret] [if: coins >= 50]
-> Ask for more coins [target:get_more]
-> End Demo [target:end]

[get_more]
$ coins = coins + 50
Miisan: (Happy) Here is 50 coins. You have ${coins} now.
-> Buy Secret [target:buy_secret]
-> End Demo [target:end]

[buy_secret]
$ coins = coins - 50
Eiisan: (Happy) You bought it!
Wiisan: (Sad) Now we are broke again...

[end]
Miisan: (Happy) Thanks for checking out LoveDialogue v1.0!
Eiisan: (Happy) Efficiency is key.
Wiisan: (Happy) Bye bye! (end)