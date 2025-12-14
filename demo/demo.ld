@portrait Miisan demo/Assets/girl.png
@portrait Eiisan demo/Assets/girl2.png
@portrait Wiisan demo/Assets/girl3.png

// Initialize variables
$ coins = 0
$ has_met_secret = false
$ name = "Traveller"

[start]
Miisan: Welcome, ${name}! This is the new Logic Demo.
Eiisan: We now have variables. You currently have ${coins} coins.
Wiisan: I'll give you some! 
$ coins = coins + 10
Wiisan: Now you have ${coins} coins! {wave:1}Rich!{/wave}

Miisan: Let's test a signal. 
Eiisan: I'll change the background color using a signal!
// Trigger a signal "ChangeBG" with args "0.5 0 0" (Red)
[signal: ChangeBG 0.5 0 0]
Wiisan: Whoa! It turned red!
Miisan: Let's turn it back.
[signal: ChangeBG 0.1 0.1 0.2]
Eiisan: Much better.

Miisan: Let's test a conditional block.
[if: coins >= 10]
    Eiisan: Wow, you really do have more than 10 coins.
    Wiisan: The logic is working perfectly!
[else]
    Eiisan: Uh oh, something is wrong. You should have coins.
[endif]

Miisan: Now, let's try a conditional choice.
Eiisan: You can only buy the secret item if you have 50 coins.
Wiisan: (You only have ${coins}...)

-> Buy Secret Item (50 coins) [target:buy_secret] [if: coins >= 50]
-> Ask for more coins [target:get_more]
-> End Demo [target:end]

[get_more]
$ coins = coins + 50
Wiisan: Fine, here is 50 more coins! You have ${coins} now.
Miisan: Try the choice again.
-> Buy Secret Item (50 coins) [target:buy_secret] [if: coins >= 50]
-> End Demo [target:end]

[buy_secret]
$ coins = coins - 50
$ has_met_secret = true
Eiisan: You bought it! You have ${coins} coins left.
Miisan: Was it worth it?
-> Yes [target:end]
-> No [target:end]

[end]
Miisan: Thanks for testing!
[if: has_met_secret]
    Wiisan: Pssst... thanks for buying my secret item.
[endif]
Eiisan: Bye! (end)