[START]
Narrator: Let's test the square demo!
-> Show the square [target:SQUARE_SHOW]
-> Skip the demo [target:NEXT_SCENE]

[SQUARE_SHOW]
Narrator: Here's the square! What should we do with it?
-> Move the square [target:SQUARE_MOVE]
-> Hide the square [target:SQUARE_HIDE]

[SQUARE_MOVE]
Narrator: The square moved! What next?
-> Hide the square [target:SQUARE_HIDE]
-> Continue to next scene [target:NEXT_SCENE]

[SQUARE_HIDE]
Narrator: The square is now hidden.
-> Continue to next scene [target:NEXT_SCENE]

[NEXT_SCENE]
Narrator: Demo completed! (end)