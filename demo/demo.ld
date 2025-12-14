// Load custom theme
[load_theme: demo/theme.ld]

// Define Sprite Atlases with Exact Coordinates
// x, y, width, height (y is 0 for all since they are 1 row)

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
Miisan: (Happy) Hello ${name}! I am using precise manual coordinates now.
Eiisan: (Happy) Me too! My texture is 302px wide.
Wiisan: (Happy) But my frames are at 0, 100, and 202.

Miisan: (Sad) This handles the 2px gap perfectly.
Eiisan: (Sad) No more bleeding edges!
Wiisan: (Mad) It is pixel perfect!

Miisan: (Happy) Let's test the signal again.
[signal: ChangeBG 0.5 0 0]
Eiisan: (Sad) Red!
[signal: ChangeBG 0.1 0.1 0.2]
Wiisan: (Happy) Blue.

-> End Demo [target:end]

[end]
Miisan: (Happy) Thanks for using LoveDialogue v1.0!
Eiisan: (Happy) Now with Atlas support.
Wiisan: (Happy) Bye bye! (end)