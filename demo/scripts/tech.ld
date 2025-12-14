// Tech Showcase
[load_theme: demo/theme.ld]

@atlas Miisan demo/assets/character_portraits/girl1_atlas.png
@rect Miisan Happy 0 0 100 108
@rect Miisan Sad 100 0 100 108
@voice Miisan demo/assets/sfx/blip.wav

@atlas Eiisan demo/assets/character_portraits/girl2_atlas.png
@rect Eiisan Happy 0 0 100 108
@voice Eiisan demo/assets/sfx/low.wav

[start]
Miisan: (Happy) Welcome to the {color:00FFFF}Tech Showcase!{/color}
Eiisan: (Happy) Watch us {jiggle:1}move{/jiggle}.

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

Miisan: (Happy) Now listen to the {wave:1}audio quality{/wave}.
Miisan: (Sad) My beep is soft.
Eiisan: (Happy) My beep is low and retro.

-> Return to Launcher [target:back]

[back]
[signal: LoadScript demo/launcher.ld]
Miisan: Loading Menu...