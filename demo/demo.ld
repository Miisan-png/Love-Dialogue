@resource font demo/Assets/font
@resource sound demo/Assets/sound
@resource background demo/Assets/background

@portrait Miisan demo/Assets/girl.png {fusion_pixel_font.ttf,15} {fusion_pixel_font.ttf,15}
@portrait Eiisan demo/Assets/girl2.png {fusion_pixel_font.ttf,15} {fusion_pixel_font.ttf,15}
@portrait Wiisan demo/Assets/girl3.png

[start]
Miisan: Hello there! I'm Miisan.{sound:guitar.wav} Welcome to the {sound:guitar.wav}LoveDialogue engine demo{sound:叮.ogg}!
Eiisan: And I'm Eiisan! We're here to demonstrate how this dialogue system works.
Wiisan: Don't forget about me! I'm Wiisan. Together we'll show you the features of this engine.

Miisan: Let's start with some basic dialogue. You can advance the text by pressing SPACE or ENTER.
Eiisan: We can use different {color:FF9900}text colors{/color} and {wave:1}special effects{/wave} too!
Wiisan: And now, let's give you a choice:

-> Learn about text effects [target:effects]
-> Learn about dialogue choices [target:choices]
-> End the demo [target:end]

[effects]
Miisan: Text effects are fun! You can make text {wave:1}wave like this{/wave}.
Eiisan: Or {shake:1}shake it up a bit{/shake} for emphasis.
Wiisan: You can use {color:FF00FF}custom colors{/color} too. Neat, right?
Miisan: What would you like to see next?
-> Go back to the start [target:start]
-> End the demo [target:end]

[choices]
Eiisan: Choices allow branching dialogue paths.
Wiisan: You navigate with the UP and DOWN arrow keys.
Miisan: Then press ENTER or SPACE to select your choice.
Eiisan: What would you like to do now?
-> Go back to the start [target:start]
-> End the demo [target:end]

[end]
Miisan: Thanks for trying out the LoveDialogue engine!
Eiisan: We hope you enjoyed this little demo.
Wiisan: See you next time! (end)