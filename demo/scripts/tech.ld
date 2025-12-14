// Tech Showcase
[load_theme: demo/theme.ld]

@atlas Miisan demo/assets/character_portraits/girl1_atlas.png
@rect Miisan Happy 0 0 100 108
@rect Miisan Sad 100 0 100 108
@voice Miisan demo/assets/sfx/blip.wav

@atlas Eiisan demo/assets/character_portraits/girl2_atlas.png
@rect Eiisan Happy 0 0 100 108
@voice Eiisan demo/assets/sfx/low.wav

// Start with flash
[fade: in 1.0 #FFFFFF]

[start]
Miisan: (Happy) Welcome to the {color:00FFFF}Tech Showcase!{/color}
Eiisan: (Happy) That was a white flash intro.

[move: Miisan 200 0 1.0]
Miisan: I am sliding to the right...
[move: Miisan 0 0 0.5]
Miisan: And snapping back!

Eiisan: (Happy) My turn!
[move: Eiisan 0 -50 0.2]
[move: Eiisan 0 0 0.2]
[move: Eiisan 0 -50 0.2]
[move: Eiisan 0 0 0.2]
Eiisan: Bounce bounce!

Miisan: (Happy) Now for a transition test...
// Fade to black
[fade: out 1.0]
// While black, change positions instantly
[move: Miisan 200 0 0]
[move: Eiisan -200 0 0]
// Fade back in to reveal new positions
[fade: in 1.0]

Miisan: (Happy) We swapped places in the dark!
Eiisan: (Happy) Magic.

-> Return to Launcher [target:back]

[back]
// Fade out before switching
[fade: out 0.5]
[signal: LoadScript demo/launcher.ld]
(end)