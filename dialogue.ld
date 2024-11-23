@portrait Alice Assets/girl.png
@portrait Ella Assets/girl2.png
@portrait Miisan Assets/girl3.png

[INTRO]
Miisan: Hello! Let's test the square demo.
-> Show the square [target:SQUARE_SHOW] @show_square
-> Skip the demo [target:NEXT_SCENE]

[SQUARE_SHOW]
Miisan: Look, a red square appeared!
-> Move the square [target:SQUARE_MOVE] @move_square
-> Hide the square [target:SQUARE_HIDE] @hide_square

[SQUARE_MOVE]
Miisan: The square moved! Want to try something else?
-> Hide the square [target:SQUARE_HIDE] @hide_square
-> Continue to next scene [target:NEXT_SCENE]

[SQUARE_HIDE]
Miisan: The square is now hidden.
-> Continue to next scene [target:NEXT_SCENE]

[NEXT_SCENE]
Miisan: Moving on to the next scene... (end)