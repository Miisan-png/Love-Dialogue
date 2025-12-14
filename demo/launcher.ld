// Launcher Menu
[load_theme: demo/theme.ld]

// Define UI Character (Invisible narrator or just text)
// We can use Miisan as the guide
@atlas Miisan demo/assets/character_portraits/girl1_atlas.png
@rect Miisan Happy 0 0 100 108
@rect Miisan Sad 100 0 100 108
@voice Miisan demo/assets/sfx/blip.wav

[start]
Miisan: (Happy) Welcome to the LoveDialogue Engine Hub!
Miisan: (Happy) Select a demo to see specific features in action.

-> Full Story Demo (Logic, Choices, Atlas) [target:load_story]
-> Tech Showcase (Movement, Audio, Tweens) [target:load_tech]
-> Quit [target:quit]

[load_story]
// Trigger signal then stop processing (infinite loop or just wait)
// The main.lua will kill this instance anyway
[signal: LoadScript demo/scripts/story.ld]
Miisan: Loading Story...

[load_tech]
[signal: LoadScript demo/scripts/tech.ld]
Miisan: Loading Tech...

[quit]
[signal: QuitGame]
(end)