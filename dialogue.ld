@portrait Miisan demo/Assets/girl.png
@portrait Eiisan demo/Assets/girl2.png
@portrait Wiisan demo/Assets/girl3.png
@Character demo/Assets/characters/feni.char

[start]
Miisan: {bold:4}{wave:1}Hello!{/wave}{/bold} I'm {italic:left}Miisan{/italic}  , and  {italic:right}welcome{/italic} to our dialogue démo!
Eiisan: And I'm Eiisan! We're here to show you the branching dialogue system.
Wiisan: Don't forget about me! I'm Wiisan, and I'll help demonstrate the portraits and text effects.
Feni: Hey, I'm Feni! I'll be here to show you character expressions.

Miisan: Who would you like to talk to first?
-> Chat with Eiisan [target:eiisan_branch]
-> Talk to Wiisan [target:wiisan_branch]
-> Ask Miisan about text effects [target:miisan_effects]
-> Talk to Feni about its feelings [target:feni_feelings]


[feni_feelings]
Feni(Happy): Hi! I'm glad you want to know more about me.
Feni: You know, people usually don't ask me how I am
Feni(Sad): It's really rough sometimes y'know?
Feni(Sad): ...
Feni(Surprised): Oh! Sorry, you're aren't here to listen to me ramble.
Feni(Determined): I'll be okay! I'm a tough cookie.

[feni_loop]
Feni: So, What ya wanna do now?
-> Chat with the others [target:return_hub]
-> Know more about me [target:feni_loop_2]

[feni_loop_2]
Feni: I'm always here to talk to you!
Feni(Sad): Sadly, I'm a really simple character.
Feni: I don't have much to say.
Feni: You won't even see me once you return to the others. That's how things are with me.
Feni(Determined): But I'm always here to listen!
Feni: So, What ya wanna do now?
-> Chat with the others [target:return_hub]
-> Know more about me [target:feni_loop_2]


[eiisan_branch]
Eiisan: {color:FFD700}Oh, you picked me! Let's talk about music.{/color}
Eiisan: I love composing! Would you like to hear about my latest piece?
-> Yes, tell me more! [target:eiisan_music]
-> Maybe later [target:return_hub]

[eiisan_music]
Eiisan: {wave:1}♪ It's a magical melody that flows like water... ♪{/wave}
Eiisan: Would you like to try composing something together?
-> Let's compose! [target:eiisan_compose] @show_square
-> I'll just listen [target:return_hub]

[eiisan_compose]
Eiisan: {jiggle:1}*excitedly pulls out a music sheet*{/jiggle}
Eiisan: Look, the square appeared! That's our musical note!
Eiisan: Shall we continue our musical journey?
-> Return to everyone else [target:return_hub]
-> Keep composing [target:eiisan_compose]

[wiisan_branch]
Wiisan: {color:98FB98}Ah, hello there! I love sharing stories about our adventures.{/color}
Wiisan: Would you like to hear about our latest expedition?
-> Yes, please tell me! [target:wiisan_story]
-> Maybe another time [target:return_hub]

[wiisan_story]
Wiisan: {shake:1}It was a stormy night in the pixel forest...{/shake}
Wiisan: {wave:1}We encountered a mysterious glowing sprite!{/wave}
Wiisan: What do you think we should have done?
-> Try to communicate with it [target:wiisan_sprite]
-> Return to safety [target:return_hub]

[wiisan_sprite]
Wiisan: The sprite danced with {color:00FF00}beautiful green lights{/color}!
Wiisan: It taught us a special dance. Want to see it?
-> Watch the dance [target:wiisan_dance] @show_square
-> Return to others [target:return_hub]

[wiisan_dance]
Wiisan: {jiggle:2}*dances gracefully*{/jiggle}
Wiisan: Look! The square is dancing too!
-> Return to everyone [target:return_hub]
-> Watch more dancing [target:wiisan_dance]

[miisan_effects]
Miisan: Oh! I'd love to show you some text effects!
Miisan: Like this {wave:1}wavy{/wave} text, or this {shake:1}shaky{/shake} one!
Miisan: And don't forget about {color:FF69B4}colors{/color}!
Miisan: What would you like to see?
-> Show more effects [target:miisan_more_effects]
-> Talk to someone else [target:return_hub]

[miisan_more_effects]
Miisan: Here's a {jiggle:2}fun effect{/jiggle}!
Miisan: And we can {color:9370DB}combine{/color} {wave:1}different{/wave} {shake:1}effects{/shake}!
Miisan: Want to try making your own effect?
-> Yes, show me! [target:miisan_create_effect] @show_square
-> Return to others [target:return_hub]

[miisan_create_effect]
Miisan: Look at the square! We can make it dance with effects!
Miisan: {wave:1}Isn't it wonderful?{/wave}
-> Return to everyone [target:return_hub]
-> Try more effects [target:miisan_more_effects]

[return_hub]
Miisan: We're all back together! What would you like to do next?
-> Chat with Eiisan [target:eiisan_branch]
-> Talk to Wiisan [target:wiisan_branch]
-> Ask Miisan about effects [target:miisan_effects]
-> End the demo [target:end_demo]

[end_demo]
Miisan: Thanks for trying out our dialogue system!
Eiisan: {wave:1}Come back soon!{/wave}
Wiisan: {color:98FB98}Bye bye!{/color} (end)