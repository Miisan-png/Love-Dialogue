" Vim syntax file for LoveDialogue (.ld) files
if exists("b:current_syntax")
  finish
endif

" Comments
syn match ldComment "//.*$"

" Variables
syn match ldVariable "\$\s*[a-zA-Z_]\w*\s*=" contains=ldVarOperator
syn match ldVarOperator "\$" contained
syn match ldVarOperator "=" contained

" Variable interpolation
syn match ldInterpolation "\${[^}]*}"

" Labels/Scenes
syn match ldLabel "^\s*\[[^:]*\]\s*$"

" Directives
syn match ldDirective "^\s*@\(sheet\|atlas\|frame\|rect\|voice\|portrait\)\s\+[a-zA-Z0-9_]\+"

" Commands
syn match ldCommand "\[signal:\|move:\|bgm:\|stop_bgm:\|load_theme:\|fade:"
syn match ldCommand "\[if:\|else\|endif\]"

" Choices
syn match ldChoice "^\s*->"

" Character names and dialogue
syn match ldCharacter "^\s*[a-zA-Z0-9_]\+\s*:" contains=ldColon
syn match ldCharacter "^\s*[a-zA-Z0-9_]\+\s*([^)]*)\s*:" contains=ldExpression,ldColon
syn match ldExpression "([^)]*)" contained
syn match ldColon ":" contained

" Text effects
syn region ldEffect start="{" end="}" contains=ldEffectType
syn match ldEffectType "\(wave\|shake\|color\|bold\|italic\)" contained

" Choice conditions
syn match ldCondition "\[target:[^]]*\]"
syn match ldCondition "\[if:[^]]*\]"

" Strings and numbers
syn match ldNumber "\<\d\+\>"
syn region ldString start='"' end='"'

" Define highlighting
hi def link ldComment Comment
hi def link ldVariable Identifier
hi def link ldVarOperator Operator
hi def link ldInterpolation Special
hi def link ldLabel Label
hi def link ldDirective PreProc
hi def link ldCommand Keyword
hi def link ldChoice Statement
hi def link ldCharacter Function
hi def link ldExpression Type
hi def link ldColon Delimiter
hi def link ldEffect Special
hi def link ldEffectType Keyword
hi def link ldCondition Conditional
hi def link ldNumber Number
hi def link ldString String

let b:current_syntax = "ld"
