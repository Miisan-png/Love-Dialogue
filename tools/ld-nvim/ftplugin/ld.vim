" Filetype plugin for LoveDialogue (.ld) files

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Set comment string for commenting
setlocal commentstring=//%s

" Set indentation
setlocal expandtab
setlocal shiftwidth=2
setlocal softtabstop=2
setlocal tabstop=2

" Folding based on labels
setlocal foldmethod=expr
setlocal foldexpr=LdFoldExpr(v:lnum)

function! LdFoldExpr(lnum)
  let line = getline(a:lnum)
  if line =~ '^\s*\[[^:]*\]\s*$'
    return '>1'
  endif
  return '='
endfunction

" Auto-pairs for brackets
if exists('g:AutoPairsLoaded')
  let b:AutoPairs = {'[': ']', '{': '}', '"': '"'}
endif

" Keywords for completion
setlocal iskeyword+=:
setlocal complete+=k

let b:undo_ftplugin = "setlocal commentstring< expandtab< shiftwidth< softtabstop< tabstop< foldmethod< foldexpr< iskeyword< complete<"
